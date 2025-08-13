@echo off
echo 🚀 Live Development Mode - Browser Console to GitHub
echo ====================================================
echo.
echo This will start a live server for you to make changes
echo in your browser's developer console, then sync them!
echo.

echo 📊 Checking git status...
git status

echo.
echo 🌐 Starting development server...
echo Your PWA will be available at: http://localhost:8000
echo.
echo 💡 HOW TO MAKE LIVE CHANGES:
echo 1. Open your browser to http://localhost:8000
echo 2. Open DevTools (F12 or Ctrl+Shift+I)
echo 3. In Elements tab: Right-click elements to edit HTML/CSS
echo 4. In Console tab: Test JavaScript changes
echo 5. In Sources tab: Edit files directly (changes are temporary)
echo.
echo 📝 When ready to save changes:
echo - Copy your changes to the actual files
echo - Run: git add . && git commit -m "Live changes" && git push
echo - Or use the sync script: ./sync-changes.sh
echo.

python -m http.server 8000
pause
