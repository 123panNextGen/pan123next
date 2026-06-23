#!/bin/bash

echo -e \
    "keytool -genkey -v -keystore \"android/app/release.keystore\" -alias release -keyalg RSA -keysize 2048 -validity 36500" \
    "-storepass $PASSWD -keypass $PASSWD -dname \"CN=$NAME, O=$ORG, L=$CITY, ST=$STATE, C=$COUNTRY\""
