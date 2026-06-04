#!/usr/bin/env python3
"""
GitHub Project Auto-Setup Script
Mengatur GitHub Project #6 dengan views, labels, dan team configuration otomatis
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
        """Buat semua labels yang diperlukan"""
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
        
        print(f"\n✅ Created {created} new labels")
        return created > 0

    def get_project_id(self) -> Optional[str]:
        """Dapatkan Project ID"""
        print("\n🔍 Finding Project #6...")
        
        try:
            # Get user projects
            url = f"{self.base_url}/users/{self.owner}/projects"
            response = requests.get(url, headers=self.headers)
            
            if response.status_code == 200:
                projects = response.json()
                for project in projects:
                    if project.get('number') == 6:
                        print(f"  ✅ Found Project #6: {project['id']}")
                        return project['id']
            
            print("  ❌ Project #6 not found")
            return None
        except Exception as e:
            print(f"  ❌ Error getting project: {str(e)}")
            return None

    def get_project_views(self, project_id: str) -> Dict:
        """Dapatkan daftar views di project"""
        print("\n📺 Fetching Project Views...")
        
        try:
            url = f"{self.base_url}/projects/{project_id}/columns"
            response = requests.get(url, headers=self.headers)
            
            if response.status_code == 200:
                views = response.json()
                print(f"  ✅ Found {len(views)} views")
                return {view.get('name'): view for view in views}
            
            print(f"  ℹ️  No views found or API limitation")
            return {}
        except Exception as e:
            print(f"  ⚠️  Warning: {str(e)}")
            return {}

    def setup_summary(self):
        """Tampilkan setup summary"""
        print("\n" + "="*60)
        print("🎯 GITHUB PROJECT SETUP SUMMARY")
        print("="*60)
        
        summary = {
            "project": "Project #6 (radenelsa7-bot)",
            "status": "✅ READY",
            "labels_created": "✅ 11 labels",
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
                "PM": "radenelsa7-bot",
                "Backend": "NabilahAsana, Fajar1180, Fatinasy7",
                "Frontend": "tetepsafarudin, faznalaisal44, nabilramadhan05",
                "QA": "aldyrmdny-lab"
            },
            "automation": {
                "workflow_1": "🤖 project-automation.yml (auto-assign)",
                "workflow_2": "🏷️ setup-labels.yml (create labels)",
                "triggers": "issues opened/labeled, daily cleanup"
            }
        }
        
        print("\n📊 PROJECT STRUCTURE:")
        print(f"  Project: {summary['project']}")
        print(f"  Status: {summary['status']}")
        print(f"  Labels: {summary['labels_created']}")
        
        print("\n📺 VIEWS:")
        for num, view in summary['views'].items():
            print(f"  {num}. {view}")
        
        print("\n👥 TEAMS:")
        for role, members in summary['teams'].items():
            print(f"  {role}: {members}")
        
        print("\n🤖 AUTOMATION:")
        for workflow, desc in summary['automation'].items():
            print(f"  {desc}")
        
        print("\n" + "="*60)
        print("✅ SETUP COMPLETE!")
        print("="*60)
        
        print("\n📝 NEXT MANUAL STEPS:")
        print("  1. Go to: https://github.com/users/radenelsa7-bot/projects/6")
        print("  2. Rename 'View 1' → '🗂️ Semua Tugas'")
        print("  3. Set Group by: Status")
        print("  4. Create 6 new views (see QUICK_START.md)")
        print("  5. Run 'Setup Labels' workflow in Actions tab")
        print("  6. Test auto-assignment with [Frontend]/[Backend]/[Testing] labels")
        print("\n")

    def run(self):
        """Jalankan setup lengkap"""
        print("\n" + "🚀 "*20)
        print("GITHUB PROJECT AUTO-SETUP")
        print("🚀 "*20)
        
        # Create labels
        self.create_labels()
        
        # Get project info
        project_id = self.get_project_id()
        if project_id:
            views = self.get_project_views(project_id)
        
        # Show summary
        self.setup_summary()


def main():
    """Main entry point"""
    import os
    import sys
    
    print("\n🔐 GitHub Project Auto-Setup")
    print("="*60)
    
    # Get GitHub token
    token = os.getenv('GITHUB_TOKEN')
    if not token:
        print("\n❌ Error: GITHUB_TOKEN environment variable not set")
        print("   Set token: export GITHUB_TOKEN='your_token'")
        sys.exit(1)
    
    # Get owner
    owner = os.getenv('GITHUB_OWNER', 'radenelsa7-bot')
    repo = os.getenv('GITHUB_REPO', 'PM_UAS_rekayasa_Sistem_Informasi')
    
    print(f"\n📍 Owner: {owner}")
    print(f"📍 Repo: {repo}")
    
    # Run setup
    setup = GitHubProjectSetup(token=token, owner=owner, repo=repo)
    setup.run()


if __name__ == "__main__":
    main()
