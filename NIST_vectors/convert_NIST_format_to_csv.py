import csv
import sys
import os

def parse_encrypt_section(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    encrypt_section = False
    data = []

    for line in lines:
        line = line.strip()
        if '[ENCRYPT]' in line:
            encrypt_section = True
            continue
        if '[DECRYPT]' in line:
            break
        if encrypt_section:
            if line.startswith('KEY = '):
                key = line.split('= ')[1]
            elif line.startswith('PLAINTEXT = '):
                plaintext = line.split('= ')[1]
            elif line.startswith('CIPHERTEXT = '):
                ciphertext = line.split('= ')[1]
                data.append((key, plaintext, ciphertext))

    return data

def write_to_csv(data, output_file):
    with open(output_file, 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['key', 'plaintext', 'ciphertext'])
        for row in data:
            writer.writerow(row)

input_file_path = sys.argv[1]
output_file = f"vectors_NIST_{os.path.basename(input_file_path).replace('.rsp', '.csv')}"
output_file = os.path.join(os.path.dirname(input_file_path), output_file)

data = parse_encrypt_section(input_file_path)
write_to_csv(data, output_file)
