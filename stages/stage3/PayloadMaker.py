#!/usr/bin/env python3
import sys

def convert_binary_to_header(binary_file, output_header):
    try:
        with open(binary_file, "rb") as f:
            binary_content = f.read()

        with open(output_header, "w") as f:
            f.write("unsigned char stage3[] = {\n")

            for i, byte in enumerate(binary_content):
                f.write(f" 0x{byte:02X}")
                if i != len(binary_content) - 1:
                    f.write(",")
                if (i + 1) % 10 == 0:
                    f.write("\n")
            f.write("\n};")

        print(f"Header file '{output_header}' created successfully.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python PayloadMaker.py <input_binary_file> <output_header_file>")
    else:
        input_binary_file = sys.argv[1]
        output_header_file = sys.argv[2]
        convert_binary_to_header(input_binary_file, output_header_file)