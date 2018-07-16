if [ ! -f ./sc-4.3.8-linux/bin/sc ]; then
  wget https://saucelabs.com/downloads/sc-4.3.8-linux.tar.gz && \
  echo "0ae5960a9b4b33e5a8e8cad9ec4b610b68eb3520 *sc-4.3.8-linux.tar.gz" | sha1sum -c - && \
  tar xvzf sc-4.3.8-linux.tar.gz && \
  rm sc-4.3.8-linux.tar.gz
fi

./sc-4.3.8-linux/bin/sc -u $SAUCE_USERNAME -k $SAUCE_ACCESS_KEY
