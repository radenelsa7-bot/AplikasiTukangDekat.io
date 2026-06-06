#!/usr/bin/env python3
"""
📌 Script Migrasi Issues dari PM_TUKANG_DEKAT ke PM_UAS_rekayasa_Sistem_Informasi

Deskripsi:
  Script ini memindahkan semua issues (buka dan tertutup) dari repository sumber
  ke repository tujuan dengan tetap menjaga:
  - Judul dan deskripsi
  - Labels/Tag
  - Assignee (penugasan)
  - Status (buka/tertutup)
  - Metadata lainnya

Prasyarat:
  pip install PyGithub python-dotenv

Setup & Penggunaan:
  1. Buat file `.env` di root direktori:
     GITHUB_TOKEN=<token_github_anda>
     
  2. Jalankan script:
     python scripts/migrasi_issues_indonesia.py

Catatan Penting:
  ✓ Script akan membaca SEMUA issues (terbuka dan tertutup)
  ✓ Issues akan dibuat BARU di repository tujuan
  ✓ Referensi original issue ditambahkan di body
  ✓ Assignee dan labels akan dipertahankan sesuai original
"""

import os
import sys
from datetime import datetime
from dotenv import load_dotenv
from github import Github, GithubException

# Load environment
load_dotenv()
TOKEN = os.getenv('GITHUB_TOKEN')

if not TOKEN:
    print("❌ ERROR: GITHUB_TOKEN tidak ditemukan di .env")
    print("📝 Buat file .env dengan: GITHUB_TOKEN=<token_github_anda>")
    sys.exit(1)

# Init GitHub client
g = Github(TOKEN)

# Repository
SOURCE_REPO = g.get_repo("radenelsa7-bot/PM_TUKANG_DEKAT")
TARGET_REPO = g.get_repo("radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi")

print("=" * 70)
print("🚀 MIGRASI ISSUES - TUKAR DEKAT KE UAS REKAYASA SISTEM INFORMASI")
print("=" * 70)
print(f"📦 Repository Sumber : {SOURCE_REPO.full_name}")
print(f"📦 Repository Tujuan : {TARGET_REPO.full_name}")
print(f"⏰ Waktu Proses      : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("=" * 70 + "\n")

def migrasi_issues():
    """Migrasi semua issues dari source ke target repository"""
    
    # Ambil SEMUA issues (buka dan tertutup)
    print("📥 Mengambil data issues dari sumber...")
    issues_list = list(SOURCE_REPO.get_issues(state='all', sort='created', direction='asc'))
    total = len(issues_list)
    
    print(f"📊 Total issues untuk dimigrasikan: {total}\n")
    
    migrated = 0
    failed = 0
    skipped = 0
    
    for idx, issue in enumerate(issues_list, 1):
        try:
            print(f"[{idx}/{total}] 🔄 Memproses: {issue.title}")
            
            # Siapkan labels
            labels = [label.name for label in issue.labels] if issue.labels else []
            
            # Siapkan assignees
            assignees = [assignee.login for assignee in issue.assignees] if issue.assignees else []
            
            # Siapkan body dengan informasi original
            original_url = issue.html_url
            original_number = issue.number
            original_state = "🔓 Terbuka" if issue.state == 'open' else "🔒 Tertutup"
            
            body = f"""## ℹ️ Hasil Migrasi dari PM_TUKANG_DEKAT

**📌 Issue Original:** [{issue.number}]({original_url})
**📅 Status Awal:** {original_state}
**📝 Dibuat:** {issue.created_at.strftime('%d-%m-%Y %H:%M')}
**🔄 Diupdate:** {issue.updated_at.strftime('%d-%m-%Y %H:%M')}

---

{issue.body if issue.body else '*(Tidak ada deskripsi)*'}
"""
            
            # Cek apakah issue sudah ada di target repo
            existing = False
            print(f"  🔍 Memeriksa duplikasi...")
            try:
                target_issues = list(TARGET_REPO.get_issues(state='all'))
                for target_issue in target_issues:
                    if target_issue.body and f"#{original_number}" in target_issue.body:
                        existing = True
                        print(f"  ⏭️  Issue #{original_number} sudah ada di repository tujuan")
                        skipped += 1
                        break
            except Exception as e:
                print(f"  ⚠️  Peringatan saat cek duplikasi: {str(e)}")
            
            if existing:
                continue
            
            # Buat issue baru di target repo
            print(f"  ✏️  Membuat issue baru...")
            new_issue = TARGET_REPO.create_issue(
                title=issue.title,
                body=body,
                labels=labels,
                assignees=assignees
            )
            
            # Set status jika closed
            if issue.state == 'closed':
                new_issue.edit(state='closed')
                print(f"  🔒 Status diubah menjadi TERTUTUP")
            
            print(f"  ✅ Berhasil dibuat: Issue #{new_issue.number}")
            if labels:
                print(f"     📌 Label: {', '.join(labels)}")
            if assignees:
                print(f"     👤 Assignee: {', '.join(assignees)}")
            print()
            
            migrated += 1
            
        except GithubException as e:
            error_msg = e.data.get('message', str(e)) if hasattr(e, 'data') else str(e)
            print(f"  ❌ Error: {error_msg}\n")
            failed += 1
        except Exception as e:
            print(f"  ❌ Error tak terduga: {str(e)}\n")
            failed += 1
    
    # Summary
    print("\n" + "=" * 70)
    print("📈 RINGKASAN HASIL MIGRASI")
    print("=" * 70)
    print(f"✅ Berhasil dimigrasikan : {migrated} issues")
    print(f"❌ Gagal              : {failed} issues")
    print(f"⏭️  Dilewati (duplikat) : {skipped} issues")
    print(f"📊 Total diproses      : {migrated + failed + skipped} issues")
    print("=" * 70)
    
    return migrated, failed, skipped

if __name__ == "__main__":
    try:
        print("🚀 Memulai proses migrasi...\n")
        migrated, failed, skipped = migrasi_issues()
        
        if migrated > 0:
            print(f"\n✨ Migrasi selesai! {migrated} issues berhasil dimigrasikan")
        else:
            print(f"\n⚠️  Tidak ada issues baru yang dimigrasikan")
            
    except KeyboardInterrupt:
        print("\n\n⚠️  Migrasi dibatalkan oleh pengguna")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        sys.exit(1)
