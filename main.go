package main

import (
   "crypto/aes"
   "crypto/cipher"
   "crypto/rand"
   "encoding/base64"
   "encoding/json"
   "errors"
   "fmt"
   "io/fs"
   "os"
   "path/filepath"
   "strconv"
   "strings"

   "github.com/spf13/cobra"
)

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

var rootCmd = &cobra.Command{
	Use:   "splace",
	Short: "Encrypted directory bookmarks manager",
	Long:  "splace manages encrypted directory bookmarks from the command line.",
}

var saveCmd = &cobra.Command{
	Use:   "s",
	Short: "Save current directory",
	RunE: func(cmd *cobra.Command, args []string) error {
		pwd, err := os.Getwd()
		if err != nil {
			return err
		}
		bookmarks, err := loadBookmarks()
		if err != nil {
			return err
		}
		bookmarks = append(bookmarks, pwd)
		if err := saveBookmarks(bookmarks); err != nil {
			return err
		}
		fmt.Println("Saved:", pwd)
		return nil
	},
}

var lastCmd = &cobra.Command{
	Use:   "l",
	Short: "Show last saved directory",
	RunE: func(cmd *cobra.Command, args []string) error {
		bookmarks, err := loadBookmarks()
		if err != nil {
			return err
		}
		if len(bookmarks) == 0 {
			fmt.Println("No bookmarks saved")
			return nil
		}
		fmt.Println(bookmarks[len(bookmarks)-1])
		return nil
	},
}

var popCmd = &cobra.Command{
	Use:   "p",
	Short: "Show and pop last saved directory",
	RunE: func(cmd *cobra.Command, args []string) error {
		bookmarks, err := loadBookmarks()
		if err != nil {
			return err
		}
		if len(bookmarks) == 0 {
			fmt.Println("No bookmarks saved")
			return nil
		}
		last := bookmarks[len(bookmarks)-1]
		bookmarks = bookmarks[:len(bookmarks)-1]
		if err := saveBookmarks(bookmarks); err != nil {
			return err
		}
		fmt.Println(last)
		return nil
	},
}

var getCmd = &cobra.Command{
	Use:   "n [index]",
	Short: "Show bookmark at index (1-based)",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		bookmarks, err := loadBookmarks()
		if err != nil {
			return err
		}
		idx, err := parseIndex(args[0], len(bookmarks))
		if err != nil {
			return err
		}
		fmt.Println(bookmarks[idx])
		return nil
	},
}

var allCmd = &cobra.Command{
	Use:   "all",
	Short: "Show all saved directories",
	RunE: func(cmd *cobra.Command, args []string) error {
		bookmarks, err := loadBookmarks()
		if err != nil {
			return err
		}
		for i, dir := range bookmarks {
			fmt.Printf("%d: %s\n", i+1, dir)
		}
		return nil
	},
}

func init() {
	rootCmd.AddCommand(saveCmd)
	rootCmd.AddCommand(lastCmd)
	rootCmd.AddCommand(popCmd)
	rootCmd.AddCommand(getCmd)
	rootCmd.AddCommand(allCmd)
}

// dataFile is the path to the encrypted bookmarks storage
var dataFile = filepath.Join(os.Getenv("HOME"), ".splace", "bookmarks.enc")
// keyFile is the path to persist the base64 encryption key
var keyFile = filepath.Join(os.Getenv("HOME"), ".splace", "key")

// getKey loads or generates a 32-byte AES key (base64) for encrypt/decrypt
func getKey() ([]byte, error) {
   // First, check environment variable
   if keyStr := os.Getenv("SPLACE_KEY"); keyStr != "" {
	   key, err := base64.StdEncoding.DecodeString(keyStr)
	   if err != nil {
		   return nil, fmt.Errorf("invalid SPLACE_KEY: %w", err)
	   }
	   if len(key) != 32 {
		   return nil, errors.New("SPLACE_KEY must be 32 bytes (base64-encoded)")
	   }
	   return key, nil
   }
   // Next, try to read from keyFile
   if data, err := os.ReadFile(keyFile); err == nil {
	   keyStr := strings.TrimSpace(string(data))
	   key, err := base64.StdEncoding.DecodeString(keyStr)
	   if err == nil && len(key) == 32 {
		   return key, nil
	   }
	   // invalid existing key, fallthrough to generate new
   }
   // Generate new key
   key := make([]byte, 32)
   if _, err := rand.Read(key); err != nil {
	   return nil, err
   }
   keyStr := base64.StdEncoding.EncodeToString(key)
   // Persist key
   dir := filepath.Dir(keyFile)
   if err := os.MkdirAll(dir, 0700); err != nil {
	   return nil, err
   }
   if err := os.WriteFile(keyFile, []byte(keyStr), 0600); err != nil {
	   return nil, err
   }
   fmt.Println("Generated new encryption key at", keyFile)
   return key, nil
}

// encrypt encrypts plaintext using AES-GCM
func encrypt(plaintext []byte) ([]byte, error) {
   key, err := getKey()
   if err != nil {
	   return nil, err
   }
   block, err := aes.NewCipher(key)
   if err != nil {
	   return nil, err
   }
   aesgcm, err := cipher.NewGCM(block)
   if err != nil {
	   return nil, err
   }
   nonce := make([]byte, aesgcm.NonceSize())
   if _, err := rand.Read(nonce); err != nil {
	   return nil, err
   }
   return aesgcm.Seal(nonce, nonce, plaintext, nil), nil
}

// decrypt decrypts data using AES-GCM
func decrypt(data []byte) ([]byte, error) {
   key, err := getKey()
   if err != nil {
	   return nil, err
   }
   block, err := aes.NewCipher(key)
   if err != nil {
	   return nil, err
   }
   aesgcm, err := cipher.NewGCM(block)
   if err != nil {
	   return nil, err
   }
   nonceSize := aesgcm.NonceSize()
   if len(data) < nonceSize {
	   return nil, errors.New("ciphertext too short")
   }
   nonce, ciphertext := data[:nonceSize], data[nonceSize:]
   return aesgcm.Open(nil, nonce, ciphertext, nil)
}

// loadBookmarks reads and decrypts the stored bookmarks
func loadBookmarks() ([]string, error) {
   data, err := os.ReadFile(dataFile)
   if err != nil {
	   if errors.Is(err, fs.ErrNotExist) {
		   return []string{}, nil
	   }
	   return nil, err
   }
   dec, err := decrypt(data)
   if err != nil {
	   return nil, err
   }
   var bookmarks []string
   if err := json.Unmarshal(dec, &bookmarks); err != nil {
	   return nil, err
   }
   return bookmarks, nil
}

// saveBookmarks encrypts and writes bookmarks to storage
func saveBookmarks(bookmarks []string) error {
   data, err := json.Marshal(bookmarks)
   if err != nil {
	   return err
   }
   enc, err := encrypt(data)
   if err != nil {
	   return err
   }
   dir := filepath.Dir(dataFile)
   if err := os.MkdirAll(dir, 0700); err != nil {
	   return err
   }
   return os.WriteFile(dataFile, enc, 0600)
}

// parseIndex converts a 1-based string index to 0-based int
func parseIndex(arg string, length int) (int, error) {
   idx, err := strconv.Atoi(arg)
   if err != nil {
	   return 0, err
   }
   if idx < 1 || idx > length {
	   return 0, fmt.Errorf("index out of range")
   }
   return idx - 1, nil
}
