# Kill everything
pkill -9 Xvfb
pkill -9 x11vnc

# Start fresh
Xvfb :99 -screen 0 1024x768x24 &
sleep 2
x11vnc -display :99 -forever -shared -nopw -cursor most -multiptr -repeat &
