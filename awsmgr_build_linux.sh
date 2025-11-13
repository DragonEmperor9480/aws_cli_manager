#/bin/sh


echo "Compiling AWS Manager"
go build -o awsmgr


echo "Installing AWS Manager"
sudo mv awsmgr /usr/local/bin/

echo "AWS Manager Installed Sucessfully!"

echo "Run 'awsmgr' to Launch it!"
