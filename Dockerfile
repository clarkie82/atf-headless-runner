FROM python:3.9-slim

ARG user=servicenow
ARG group=servicenow
ARG uid=1000
ARG gid=1000

ENV SERVICENOW_HOME=/var/servicenow \
    LANG=C.UTF-8

# Update debian buster
RUN apt-get clean && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Create ServiceNow User
RUN mkdir -p $SERVICENOW_HOME && \
    chown ${uid}:${gid} $SERVICENOW_HOME && \
    groupadd -g ${gid} ${group} && \
    useradd -d "$SERVICENOW_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

# Install Firefox
#RUN echo "deb [arch=amd64] http://ftp.de.debian.org/debian buster main" >> /etc/apt/sources.list && \
    #apt-get update -y && \
    #apt-get install -y --no-install-recommends gpgv apt curl firefox-esr gdebi sudo gnupg2 wget
# Geckodriver - https://firefox-source-docs.mozilla.org/testing/geckodriver/Support.html

# Install Chrome & RobotFramework
WORKDIR $SERVICENOW_HOME

# Install Chrome - https://developer.chrome.com/docs/chromedriver/downloads/version-selection
# https://storage.googleapis.com/chrome-for-testing-public/133.0.6943.98/linux64/chrome-linux64.zip
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo tee /etc/apt/trusted.gpg.d/googlerepo.asc && \
    sudo sh -c 'echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' && \
    sudo apt-get update && \
    sudo apt-get install -y google-chrome-stable chromium-driver && \
    /opt/google/chrome/chrome --version

# Install Robot Framework
RUN pip install --upgrade pip && \
    pip install robotframework robotframework-seleniumlibrary robotframework-requests

# Configure RobotFramework - should be in PATH so may not be needed
RUN webdrivermanager firefox chrome --linkpath /usr/local/bin && \
    chown -R ${user}:${user} ${SERVICENOW_HOME} && \
    rm -f ${CHROME_RELEASE}.deb && PATH=$PATH:${SERVICENOW_HOME}/.local/bin

COPY robot.robot $SERVICENOW_HOME

# Run as non-root user
USER ${user}
ENTRYPOINT robot robot.robot
