#!/usr/bin/python
import sys

def convert_arabic_persian_to_english(number_str):
    # Dictionary to map Arabic/Persian numerals to English numerals
    arabic_persian_to_english = {
        '۰': '0', '٠': '0',
        '۱': '1', '١': '1',
        '۲': '2', '٢': '2',
        '۳': '3', '٣': '3',
        '۴': '4', '٤': '4',
        '۵': '5', '٥': '5',
        '۶': '6', '٦': '6',
        '۷': '7', '٧': '7',
        '۸': '8', '٨': '8',
        '۹': '9', '٩': '9'
    }

    # Replace each Arabic/Persian numeral with the corresponding English numeral
    english_number_str = ''.join(arabic_persian_to_english.get(char, char) for char in number_str)
    return english_number_str

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python convert.py <arabic_persian_number>")
        sys.exit(1)

    arabic_persian_number = sys.argv[1]
    english_number = convert_arabic_persian_to_english(arabic_persian_number)
    print(english_number)

