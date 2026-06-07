#!/usr/bin/env python3
"""
Script untuk migrasi Issues dari PM_TUKANG_DEKAT ke PM_UAS_rekayasa_Sistem_Informasi

Requirements:
    pip install PyGithub python-dotenv

Setup:
    1. Buat file `.env` di root direktori dengan isi:
       GITHUB_TOKEN=<your_github_token>
       
    2. Run script:
       python scripts/migrate_issues.py

Note:
    - Script akan membaca semua issues dari PM_TUKANG_DEKAT (open + closed)
    - Akan membuat issues baru di PM_UAS_rekayasa_Sistem_Informasi dengan detail lengkap
    - Assignee dan labels akan dipertahankan sesuai asli
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
    print("Buat file .env dengan: GITHUB_TOKEN=<your_token>")
    sys.exit(1)

# Init GitHub client
g = Github(TOKEN)

# Repository
SOURCE_REPO = g.get_repo("radenelsa7-bot/PM_TUKANG_DEKAT")
TARGET_REPO = g.get_repo("radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi")

print(f"📦 Source Repository: {SOURCE_REPO.full_name}")
print(f"📦 Target Repository: {TARGET_REPO.full_name}\n")

def migrate_issues():
    """Migrate all issues from source to target repository"""
    
    issues_list = SOURCE_REPO.get_issues(state='all', sort='created', direction='asc')
    total = issues_list.totalCount
    
    print(f"📊 Total issues untuk dimigrasikan: {total}\n")
    
    migrated = 0
    failed = 0
    skipped = 0
    
    for idx, issue in enumerate(issues_list, 1):
        try:
            print(f"[{idx}/{total}] Processing: {issue.title}")
            
            # Prepare labels
            labels = [label.name for label in issue.labels]
            
            # Prepare assignees
            assignees = [assignee.login for assignee in issue.assignees]
            
            # Prepare body dengan info asli
            original_url = issue.html_url
            original_number = issue.number
            body = f"""## ℹ️ Migrated from PM_TUKANG_DEKAT

**Original Issue:** [{issue.number}]({original_url})
**Original Created:** {issue.created_at}
**Original Updated:** {issue.updated_at}

---

{issue.body or '*(no description)*'}
"""
            
            # Check if issue sudah ada di target
            existing = False
            try:
                target_issues = TARGET_REPO.get_issues(state='all')
                for target_issue in target_issues:
                    if f"#{original_number}" in target_issue.body:
                        existing = True
                        print(f"  ⏭️  Issue #{original_number} sudah ada di target repo")
                        skipped += 1
                        break
            except:
                pass
            
            if existing:
                continue
            
            # Create issue di target repo
            new_issue = TARGET_REPO.create_issue(
                title=issue.title,
                body=body,
                labels=labels,
                assignees=assignees
            )
            
            # Set state jika closed
            if issue.state == 'closed':
                new_issue.edit(state='closed')
            
            print(f"  ✅ Created issue #{new_issue.number}")
            print(f"     Labels: {', '.join(labels) if labels else 'none'}")
            print(f"     Assignees: {', '.join(assignees) if assignees else 'none'}\n")
            
            migrated += 1
            
        except GithubException as e:
            print(f"  ❌ Error: {e.data.get('message', str(e))}\n")
            failed += 1
        except Exception as e:
            print(f"  ❌ Unexpected error: {str(e)}\n")
            failed += 1
    
    # Summary
    print("\n" + "="*60)
    print("📈 MIGRATION SUMMARY")
    print("="*60)
    print(f"✅ Berhasil dimigrasikan: {migrated}")
    print(f"❌ Gagal: {failed}")
    print(f"⏭️  Skipped (sudah ada): {skipped}")
    print(f"📊 Total diproses: {migrated + failed + skipped}")
    print("="*60)
    
    return migrated, failed, skipped

if __name__ == "__main__":
    try:
        print("🚀 Starting migration...\n")
        migrate_issues()
        print("\n✨ Migration complete!")
    except KeyboardInterrupt:
        print("\n\n⚠️  Migration cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        sys.exit(1)
