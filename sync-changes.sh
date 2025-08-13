#!/bin/bash

echo "🔄 Syncing Live Changes to GitHub"
echo "=================================="

# Check git status
echo "📊 Current changes:"
git status

echo ""
echo "📝 Staging all changes..."
git add .

echo ""
echo "💬 Enter commit message (or press Enter for default):"
read -r commit_msg

if [ -z "$commit_msg" ]; then
    commit_msg="Live dev changes - $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo "📝 Committing with message: $commit_msg"
git commit -m "$commit_msg"

echo ""
echo "🚀 Pushing to GitHub..."
git push origin main

echo ""
echo "✅ Changes synced to GitHub!"
echo "🌐 Your live changes are now deployed!"
