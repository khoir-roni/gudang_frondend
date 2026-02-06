# hapus_nomor_labels.py

# Buka file labels.txt
with open("labels.txt", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Hapus angka di depan setiap baris
cleaned = []
for line in lines:
    # Pisahkan berdasarkan spasi, ambil bagian setelah angka
    parts = line.strip().split(" ", 1)
    if len(parts) == 2:
        cleaned.append(parts[1])  # ambil label tanpa angka
    else:
        cleaned.append(parts[0])  # kalau tidak ada angka, tetap

# Simpan hasil ke file baru
with open("labels_clean.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(cleaned))

print("Selesai! File labels_clean.txt sudah dibuat.")
