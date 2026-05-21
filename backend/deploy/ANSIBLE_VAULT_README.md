Ansible Vault — Panduan Singkat

Tujuan: jelaskan cara membuat file `deploy/secrets/vault_env.yml` terenkripsi dan menjalankan playbook.

1) Buat file plaintext `deploy/secrets/vault_env.yml` dengan isi variabel, contoh:

```
XENDIT_API_KEY: "sk_prod_..."
DB_PASSWORD: "supersecret"
```

2) Enkripsi file dengan Ansible Vault:

```bash
ansible-vault encrypt deploy/secrets/vault_env.yml
```

3) Menjalankan playbook dengan password prompt:

```bash
ansible-playbook -i deploy/ansible_inventory.example deploy/ansible_set_secrets.yml --ask-vault-pass
```

4) Menjalankan playbook dengan file password (lebih nyaman untuk CI, simpan password dengan aman):

```bash
ansible-playbook -i deploy/ansible_inventory.example deploy/ansible_set_secrets.yml --vault-password-file ~/.vault_pass
```

Catatan keamanan:
- Jangan commit file plaintext `vault_env.yml`.
- Simpan password vault di lokasi aman dan hanya berikan akses pada account deploy.
- Ansible Vault cocok untuk small-scale secret management; untuk produksi besar, gunakan secret manager (Vault, AWS Secrets Manager, etc.).
