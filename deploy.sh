sudo cp systemd/articles.service /etc/systemd/system/articles.service
sudo cp systemd/articles.timer /etc/systemd/system/articles.timer
sudo systemctl daemon-reload
sudo systemctl enable articles.service
sudo systemctl start articles.service
sudo systemctl enable articles.timer
