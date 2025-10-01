using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading;

namespace TabInterface
{
    class Program
    {
        private static List<KeyValuePair<string, string>> suggestions;
        private static int selectedIndex = 0;
        private static string currentInput = "";
        private static string tempFile;

        static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("No input file provided.");
                Environment.Exit(1);
            }

            tempFile = args[0];
            LoadSuggestions();

            if (suggestions.Count == 0)
            {
                Console.WriteLine("No custom suggestions available.");
                Environment.Exit(1);
            }

            Console.CursorVisible = false;
            DisplayInterface();

            while (true)
            {
                var key = Console.ReadKey(true);
                
                switch (key.Key)
                {
                    case ConsoleKey.UpArrow:
                        MoveSelection(-1);
                        break;
                    case ConsoleKey.DownArrow:
                        MoveSelection(1);
                        break;
                    case ConsoleKey.Enter:
                        SelectSuggestion();
                        return;
                    case ConsoleKey.Escape:
                        Environment.Exit(0);
                        return;
                    case ConsoleKey.Tab:
                        CycleTabs();
                        break;
                }
            }
        }

        static void LoadSuggestions()
        {
            try
            {
                var json = File.ReadAllText(tempFile);
                using JsonDocument doc = JsonDocument.Parse(json);
                var root = doc.RootElement;

                // Get current input for filtering
                if (root.TryGetProperty("CurrentInput", out var inputElement))
                {
                    currentInput = inputElement.GetString() ?? "";
                }

                suggestions = new List<KeyValuePair<string, string>>();

                if (root.TryGetProperty("CustomSuggestions", out var suggestionsElement))
                {
                    foreach (var property in suggestionsElement.EnumerateObject())
                    {
                        suggestions.Add(new KeyValuePair<string, string>(
                            property.Name,
                            property.Value.GetString() ?? ""
                        ));
                    }
                }

                // Filter suggestions based on current input if any
                if (!string.IsNullOrWhiteSpace(currentInput))
                {
                    suggestions = suggestions
                        .Where(s => s.Key.ToLower().Contains(currentInput.ToLower()) || 
                                   s.Value.ToLower().Contains(currentInput.ToLower()))
                        .ToList();
                }

                // Sort by name
                suggestions = suggestions.OrderBy(s => s.Key).ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading suggestions: {ex.Message}");
                suggestions = new List<KeyValuePair<string, string>>();
            }
        }

        static void DisplayInterface()
        {
            Console.Clear();
            Console.WriteLine("=== Custom Autofill Suggestions ===");
            Console.WriteLine("Use ↑↓ arrows to navigate, Enter to select, Esc to cancel");
            Console.WriteLine("Tab: Cycle between filtered views");
            Console.WriteLine($"Current input: {(string.IsNullOrEmpty(currentInput) ? "(none)" : currentInput)}");
            Console.WriteLine();

            for (int i = 0; i < suggestions.Count; i++)
            {
                var suggestion = suggestions[i];
                if (i == selectedIndex)
                {
                    Console.BackgroundColor = ConsoleColor.White;
                    Console.ForegroundColor = ConsoleColor.Black;
                }
                else
                {
                    Console.BackgroundColor = ConsoleColor.Black;
                    Console.ForegroundColor = ConsoleColor.Gray;
                }

                Console.WriteLine($" {suggestion.Key,-30} : {Truncate(suggestion.Value, 40)} ");
            }

            Console.ResetColor();
            Console.WriteLine();
            Console.WriteLine("Press Enter to insert selection, Esc to cancel");
        }

        static void MoveSelection(int direction)
        {
            selectedIndex += direction;

            if (selectedIndex < 0)
                selectedIndex = suggestions.Count - 1;
            else if (selectedIndex >= suggestions.Count)
                selectedIndex = 0;

            DisplayInterface();
        }

        static void CycleTabs()
        {
            // This could be enhanced to cycle between different views
            // For now, just refresh the display
            DisplayInterface();
        }

        static void SelectSuggestion()
        {
            if (selectedIndex >= 0 && selectedIndex < suggestions.Count)
            {
                var selected = suggestions[selectedIndex].Value;
                
                // Write the selected suggestion back to the temp file
                var result = new { SelectedSuggestion = selected };
                var json = JsonSerializer.Serialize(result);
                File.WriteAllText(tempFile, json);
                
                Environment.Exit(0);
            }
            else
            {
                Environment.Exit(1);
            }
        }

        static string Truncate(string value, int maxLength)
        {
            if (string.IsNullOrEmpty(value)) return value;
            return value.Length <= maxLength ? value : value.Substring(0, maxLength - 3) + "...";
        }
    }
}