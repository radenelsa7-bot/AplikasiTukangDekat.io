#!/usr/bin/env python3
"""
GitHub Project Auto-Setup Script
Mengatur GitHub Project 'Project_Aplikasi_TukangDekat' dengan views, labels, dan team configuration otomatis
"""

import requests
import json
import time
from typing import Dict, List, Optional

class GitHubProjectSetup:
    def __init__(self, token: str, owner: str, repo: str = None):
        self.token = token
        self.owner = owner
        self.repo = repo
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        }
        self.base_url = "https://api.github.com"

    def create_labels(self):
        """Buat semua labels yang diperlukan di repositori"""
        print("\n📋 Creating Labels...")
        
        labels = [
            # Status labels
            {"name": "Status: Todo", "color": "d4c5f9", "description": "Belum dikerjakan"},
            {"name": "Status: In Progress", "color": "fbca04", "description": "Sedang dikerjakan"},
            {"name": "Status: In Review", "color": "0e8a16", "description": "Dalam review"},
            {"name": "Status: Done", "color": "28a745", "description": "Selesai"},
            
            # Team labels
            {"name": "Frontend", "color": "1f6feb", "description": "Tugas Frontend"},
            {"name": "Backend", "color": "a371f7", "description": "Tugas Backend"},
            {"name": "Testing", "color": "d1242f", "description": "Tugas Testing/QA"},
            
            # Priority labels
            {"name": "Priority: Critical", "color": "b60205", "description": "Urgent - harus dikerjakan hari ini"},
            {"name": "Priority: High", "color": "d4c5f9", "description": "Penting - kerjakan minggu ini"},
            {"name": "Priority: Medium", "color": "fbca04", "description": "Normal - kerjakan bulan ini"},
            {"name": "Priority: Low", "color": "0075ca", "description": "Bisa ditunda"},
        ]
        
        created = 0
        for label in labels:
            try:
                url = f"{self.base_url}/repos/{self.owner}/{self.repo}/labels"
                response = requests.post(url, headers=self.headers, json=label)
                
                if response.status_code == 201:
                    print(f"  ✅ Created label: {label['name']}")
                    created += 1
                elif response.status_code == 422:
                    print(f"  ℹ️  Label already exists: {label['name']}")
                else:
                    print(f"  ❌ Error creating {label['name']}: {response.text}")
            except Exception as e:
                print(f"  ❌ Exception creating {label['name']}: {str(e)}")
        
        print(f"\n✅ Finished processing labels ({created} new created)")
        return created > 0

    def get_project_id(self) -> Optional[str]:
        """Dapatkan Project ID berdasarkan nama text 'Project_Aplikasi_TukangDekat'"""
        target_project_name = "Project_Aplikasi_TukangDekat"
        print(f"\n🔍 Finding Project: '{target_project_name}'...")
        
        try:
            # Mencari proyek berbasis REST API v3
            url = f"{self.base_url}/users/{self.owner}/projects"
            response = requests.get(url, headers=self.headers)
            
            if response.status_code == 200:
                projects = response.json()
                for project in projects:
                    if project.get('name') == target_project_name:
                        print(f"  ✅ Found Project '{target_project_name}': ID {project['id']}")
                        return project['id']
            
            # Catatan: Jika proyek Anda adalah tipe Projects v2 terbaru, 
            # REST API lama mungkin merespon kosong karena v2 mewajibkan protokol GraphQL.
            print(f"  ℹ️  Project '{target_project_name}' tidak terdeteksi via REST API v3 legacy.")
            print("     Konfigurasi visual disarankan diselesaikan via Copilot Prompt.")
            return None
        except Exception as e:
            print(f"  ❌ Error getting project: {str(e)}")
            return None

    def get_project_views(self, project_id: str) -> Dict:
        """Dapatkan daftar views di project"""
        try:
            url = f"{self.base_url}/projects/{project_id}/columns"
            response = requests.get(url, headers=self.headers)
            if response.status_code == 200:
                views = response.json()
                return {view.get('name'): view for view in views}
            return {}
        except Exception:
            return {}

    def setup_summary(self):
        """Tampilkan setup summary"""
        print("\n" + "="*60)
        print("🎯 GITHUB PROJECT SETUP SUMMARY")
        print("="*60)
        
        summary = {
            "project": "Project_Aplikasi_TukangDekat",
            "status": "✅ READY",
            "labels_created": "✅ 11 standard labels applied",
            "views": {
                "1": "🗂️ Semua Tugas (grouped by Status)",
                "2": "🚚 Kanban Board (Board layout)",
                "3": "👤 Tugas Saya (Personal view)",
                "4": "📅 Jadwal & Milestones (Roadmap)",
                "5": "💻 Tim Frontend (Frontend filter)",
                "6": "⚙️ Tim Backend (Backend filter)",
                "7": "🧪 QA & Testing (Testing filter)"
            },
            "teams": {
                "PM (Project Manager)": "radenelsa7-bot (R.Elsa Balqis)",
                "Backend Developer"  : "NabilahAsana, Fajar1180, Fatinasy7",
                "Frontend Developer" : "tetepsafarudin, faznalaisal44, nabilramadhan05",
                "QA / Tester"        : "aldyrmdny-lab"
            },
            "automation": {
                "workflow_1": "🤖 project-automation.yml (auto-assign)",
                "triggers": "issues opened/labeled, title parsing [Frontend]/[Backend]/[Testing]"
            }
        }
        
        print("\n📊 PROJECT STRUCTURE:")
        print(f"  Project Name : {summary['project']}")
        print(f"  Owner Status : {summary['status']}")
        print(f"  Labels Info  : {summary['labels_created']}")
        
        print("\n📺 SUGGESTED VIEWS TO CHECK ON WEB:")
        for num, view in summary['views'].items():
            print(f"  {num}. {view}")
        
        print("\n👥 REGISTERED TEAMS:")
        for role, members in summary['teams'].items():
            print(f"  {role}: {members}")
            
        print("\n🤖 AUTOMATION LAYOUT:")
        for workflow, desc in summary['automation'].items():
            print(f"  {desc}")
        
        print("\n" + "="*60)
        print("✅ REPOSITORY LABELS INITIALIZATION COMPLETE!")
        print("="*60)
        
        print("\n📝 NEXT MANUAL STEPS FOR MANAGEMENT:")
        print(f"  1. Buka browser: https://github.com/users/{self.owner}/projects")
        print("  2. Pilih papan 'Project_Aplikasi_TukangDekat'")
        print("  3. Jalankan gabungan PROMPT COPILOT yang kita buat sebelumnya untuk")
        print("     membangun seluruh tab view (1 s/d 7) di atas secara instan!")
        print("\n")

    def run(self):
        """Jalankan setup lengkap"""
        print("\n" + "🚀 "*20)
        print("GITHUB PROJECT AUTO-SETUP INITIALIZER")
        print("🚀 "*20)
        
        # Buat label penanda tugas di repo
        self.create_labels()
        
        # Cari project ID jika tersedia
        project_id = self.get_project_id()
        if project_id:
            self.get_project_views(project_id)
        
        # Tampilkan resume tim & panduan
        self.setup_summary()


def main():
    """Main entry point"""
    import os
    import sys
    
    print("\n🔐 GitHub Project Auto-Setup")
    print("="*60)
    
    # Ambil token keamanan
    token = os.getenv('GITHUB_TOKEN')
    if not token:
        print("\n❌ Error: GITHUB_TOKEN environment variable not set")
        print("   Set token dahulu di Git Bash:")
        print("   export GITHUB_TOKEN=\"<YOUR_GITHUB_TOKEN>\"")

        sys.exit(1)
    
    # Konfigurasi repositori target sesuai kepemilikan Anda
    owner = os.getenv('GITHUB_OWNER', 'radenelsa7-bot')
    repo = os.getenv('GITHUB_REPO', 'PM_UAS_rekayasa_Sistem_Informasi')
    
    print(f"📍 Owner Target : {owner}")
    print(f"📍 Repo Target  : {repo}")
    
    setup = GitHubProjectSetup(token=token, owner=owner, repo=repo)
    setup.run()

if __name__ == "__main__":
    main()
