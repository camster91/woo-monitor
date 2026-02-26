#!/usr/bin/env python3
"""
Simple script to create WooCommerce Monitor application in Coolify
"""

import json
import requests
import time

# Coolify API configuration
COOLIFY_URL = "http://187.77.26.99:8000"
API_TOKEN = "2|OyUt8feqoaBUVu1Uvvkq59CCqNjIdj4j2Vf0OXYf"
HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json",
    "Accept": "application/json"
}

def get_taekwondo_app():
    """Get taekwondo app as template"""
    url = f"{COOLIFY_URL}/api/v1/applications/ug8ogwo44og0gossc0gsoosw"
    try:
        response = requests.get(url, headers=HEADERS, timeout=10)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Failed to get taekwondo app: {response.status_code}")
            return None
    except Exception as e:
        print(f"Error getting taekwondo app: {e}")
        return None

def create_woomonitor_app(template_app):
    """Create woo-monitor app from template"""
    # Remove fields that should not be in creation request
    fields_to_remove = [
        'uuid', 'id', 'created_at', 'updated_at', 'deleted_at',
        'last_online_at', 'last_restart_at', 'last_restart_type',
        'restart_count', 'config_hash', 'server_status', 'status',
        'fqdn', 'custom_labels', 'custom_nginx_configuration'
    ]
    
    for field in fields_to_remove:
        if field in template_app:
            del template_app[field]
    
    # Update with woo-monitor specific values
    template_app['name'] = 'WooCommerce Monitor'
    template_app['description'] = 'WooCommerce error monitoring and alert system'
    template_app['git_repository'] = 'camster91/woo-monitor'
    template_app['git_branch'] = 'master'
    template_app['build_pack'] = 'dockerfile'  # Use Dockerfile
    template_app['ports_exposes'] = '3000'
    template_app['health_check_path'] = '/api/health'
    template_app['health_check_port'] = 3000
    template_app['health_check_enabled'] = True
    template_app['redirect'] = 'both'
    
    # Try to create the application
    url = f"{COOLIFY_URL}/api/v1/applications"
    
    print("Creating WooCommerce Monitor application...")
    print(f"Repository: {template_app['git_repository']}")
    print(f"Branch: {template_app['git_branch']}")
    
    try:
        response = requests.post(url, json=template_app, headers=HEADERS, timeout=30)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200 or response.status_code == 201:
            print("SUCCESS: Application created successfully!")
            result = response.json()
            print(f"Application UUID: {result.get('uuid', 'Unknown')}")
            return result
        else:
            print(f"ERROR: Failed to create application: {response.status_code}")
            print(f"Response: {response.text[:500]}")
            return None
            
    except Exception as e:
        print(f"ERROR: Error creating application: {e}")
        return None

def main():
    print("=== WooCommerce Monitor Coolify Deployment ===")
    
    # Get template app
    print("Getting taekwondo app as template...")
    template = get_taekwondo_app()
    if not template:
        print("Failed to get template. Using minimal configuration.")
        # Create minimal config
        minimal_config = {
            "name": "WooCommerce Monitor",
            "git_repository": "camster91/woo-monitor",
            "git_branch": "master",
            "build_pack": "dockerfile",
            "ports_exposes": "3000",
            "environment_id": 2,
            "destination_id": 0,
            "source_id": 0,
            "source_type": "App\\Models\\GithubApp",
            "health_check_enabled": True,
            "health_check_path": "/api/health",
            "redirect": "both"
        }
        create_woomonitor_app(minimal_config)
    else:
        # Create from template
        create_woomonitor_app(template)

if __name__ == "__main__":
    main()