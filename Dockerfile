FROM ubuntu:18.04 as base

FROM base as installer-downloader
ARG amass_version=v3.5.4
WORKDIR /opt/tools
RUN  apt-get update && \
  apt-get install -y wget unzip && \
  rm -rf /var/lib/apt/lists/* && \
  wget -q https://github.com/OWASP/Amass/releases/download/$amass_version/amass_"$amass_version"_linux_amd64.zip && \
  wget -q https://github.com/OWASP/Amass/releases/download/$amass_version/amass_checksums.txt && \
  cat amass_checksums.txt | grep amass_"$amass_version"_linux_amd64.zip | sha256sum -c - && \
  unzip amass_"$amass_version"_linux_amd64.zip && \
  cp amass_"$amass_version"_linux_amd64/amass . && \
  rm -rf amass_*

FROM golang:1.14 as installer-go
RUN \
  go get -u \
    github.com/michenriksen/aquatone \
    github.com/tomnomnom/httprobe \
    github.com/tomnomnom/unfurl \
    github.com/tomnomnom/waybackurls

FROM golang:1.14 as installer-git
WORKDIR /opt
RUN git clone --depth=1 https://github.com/nahamsec/recon_profile.git

WORKDIR /opt/gittools
RUN \
  git clone --depth=1 https://github.com/nahamsec/JSParser.git && \
  git clone --depth=1 https://github.com/aboul3la/Sublist3r.git && \
  git clone --depth=1 https://github.com/tomdev/teh_s3_bucketeers.git && \
  git clone --depth=1 https://github.com/maurosoria/dirsearch.git && \
  git clone --depth=1 https://github.com/nahamsec/lazys3.git && \
  git clone --depth=1 https://github.com/jobertabma/virtual-host-discovery.git && \
  git clone --depth=1 https://github.com/sqlmapproject/sqlmap.git sqlmap-dev && \
  git clone --depth=1 https://github.com/guelfoweb/knock.git && \
  git clone --depth=1 https://github.com/nahamsec/lazyrecon.git && \
  git clone --depth=1 https://github.com/blechschmidt/massdns.git && \
  git clone --depth=1 https://github.com/yassineaboukir/asnlookup.git && \
  git clone --depth=1 https://github.com/nahamsec/crtndstry.git && \
  git clone --depth=1 https://github.com/danielmiessler/SecLists.git

FROM base as runner
ARG user=runner
ARG home_dir=/home/$user
ARG tools_dir=$home_dir/tools
ARG bin_dir=$home_dir/.local/bin
ARG recon_profile_path=$home_dir/.recon_profile

ENV PATH $PATH:$bin_dir
ENV BASH_ENV $recon_profile_path

RUN \
  useradd --create-home --shell /bin/bash $user && \
  apt-get update && apt-get install -y --no-install-recommends --quiet \
  # pip
  libcurl4-openssl-dev libssl-dev \
  # wpscan
  curl ruby-full build-essential patch ruby-dev zlib1g-dev liblzma-dev \
  jq \
  # python
  python3 python3-dev python3-setuptools python3-pip python-dnspython \
  python-dev python-pip python-setuptools && \
  rm -rf /var/lib/apt/lists/* && \
  gem install wpscan && gem sources -c

COPY --from=installer-git --chown=$user:$user /opt/gittools $tools_dir
COPY --from=installer-git --chown=$user:$user /opt/recon_profile/.bash_profile $recon_profile_path
COPY --from=installer-go --chown=$user:$user /go/bin $bin_dir
COPY --from=installer-downloader --chown=$user:$user /opt/tools $bin_dir

RUN \
  pip install -r $tools_dir/Sublist3r/requirements.txt && \
  cd $tools_dir/massdns && make && \
  pip install -r $tools_dir/asnlookup/requirements.txt && \
  cd $tools_dir/JSParser && python setup.py install && \
  pip install awscli

USER $user

##THIS FILE BREAKS MASSDNS AND NEEDS TO BE CLEANED
RUN \
  cd $tools_dir/SecLists/Discovery/DNS && \
  cat dns-Jhaddix.txt | head -n -14 > clean-jhaddix-dns.txt

WORKDIR $tools_dir

ENTRYPOINT ["/bin/bash", "-c"]
