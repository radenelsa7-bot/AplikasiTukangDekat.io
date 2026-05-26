<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;

class DeploySmokeTest extends Command
{
    protected $signature = 'deploy:smoke {--force} {--url=}';
    protected $description = 'Run deployment smoke checks after staging/production deploy.';

    public function handle()
    {
        if (app()->environment('production') && !$this->option('force')) {
            $this->error('Command ini hanya boleh dijalankan di production jika menggunakan --force.');
            return 1;
        }

        $baseUrl = $this->option('url') ?: Config::get('app.url') ?: env('APP_URL', 'http://127.0.0.1');
        $healthUrl = rtrim($baseUrl, '/') . '/api/catalog/categories';

        $this->info('Starting deploy smoke test');
        $this->line('Health endpoint: ' . $healthUrl);

        if (! $this->checkHttpHealth($healthUrl)) {
            return 1;
        }

        $this->info('Running artisan readiness commands...');

        if (! $this->runArtisanCommand('migrate:status', ['--force' => true])) {
            return 1;
        }

        $this->runArtisanCommand('queue:failed');

        if (! $this->runArtisanCommand('payouts:process', ['--dry-run' => true])) {
            return 1;
        }

        if (! $this->runArtisanCommand('payouts:process-pending', ['--limit' => 1])) {
            return 1;
        }

        $this->info('Deploy smoke test completed successfully.');
        return 0;
    }

    protected function checkHttpHealth(string $url): bool
    {
        try {
            $response = Http::timeout(10)->get($url);
        } catch (\Throwable $e) {
            $this->error('HTTP health check failed: ' . $e->getMessage());
            return false;
        }

        if ($response->successful()) {
            $this->info('HTTP health check passed (status ' . $response->status() . ')');
            return true;
        }

        $this->error('HTTP health check failed (status ' . $response->status() . ')');
        return false;
    }

    protected function runArtisanCommand(string $command, array $options = []): bool
    {
        $this->line('Executing: php artisan ' . $command . ' ' . $this->formatOptions($options));
        $exitCode = Artisan::call($command, $options);

        $this->output->write(Artisan::output());

        if ($exitCode !== 0) {
            $this->error('Command failed: ' . $command);
            return false;
        }

        return true;
    }

    protected function formatOptions(array $options): string
    {
        $result = [];

        foreach ($options as $key => $value) {
            if (is_bool($value)) {
                $result[] = $value ? '--' . $key : '';
                continue;
            }

            $result[] = '--' . $key . '=' . $value;
        }

        return implode(' ', array_filter($result));
    }
}
