import pandas as pd

# Load the Excel file
excel_file_path = "C:/Users/Andre/OneDrive/Dokumenter/bachelor/bachelor/data.xlsx"  # Change to your actual file path
df = pd.read_excel(excel_file_path, sheet_name=0)  # Loads the first sheet


# Save it as a new CSV file
csv_file_path = "C:/Users/Andre/OneDrive/Dokumenter/bachelor/bachelor/Data.csv"  # Define your output CSV file name
df.to_csv(csv_file_path, index=False, encoding='utf-8', sep=';')

print(f"Excel file has been successfully converted to: {csv_file_path}")
