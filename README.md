<h1 align="center">
  <img src="screenshots/axiom_banner.png" alt="axiom"></a>
  <br>
 </h1>

[![License](https://img.shields.io/badge/license-MIT-_red.svg)](https://opensource.org/licenses/MIT)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/pry0cc/axiom/issues)
[![Follow on Twitter](https://img.shields.io/twitter/follow/pry0cc.svg?logo=twitter)](https://twitter.com/pry0cc)
[![Follow on Twitter](https://img.shields.io/twitter/follow/0xtavian.svg?logo=twitter)](https://twitter.com/0xtavian)


<p align="center">
<a href="https://github.com/pry0cc/axiom/wiki" target="_blank"> <img src="https://github.com/projectdiscovery/nuclei/raw/367d12700e252ec7066c79b1b97a6427544d931c/static/read-the-docs-button.png" height="42px"/></a>
</p> 

**Axiom is a dynamic infrastructure framework** to efficiently work with multi-cloud environments, build and deploy repeatable infrastructure focussed on offensive and defensive security. 

Axiom works by pre-installing your tools of choice onto a 'base image', and then using that image to deploy fresh instances. From there, you can connect and instantly gain access to many tools useful for both bug hunters and pentesters. With the power of immutable infrastructure, most of which is done for you, you can just spin up 15 boxes, perform a distributed nmap/ffuf/screenshotting scan, and then shut them down.  

Because you can create many disposable instances very easily, axiom allows you to distribute scans of many different tools including amass aquatone arjun assetfinder cf-check cngo commix corsy crlfuzz crobat ctfr dalfox dirdar dnscewl dnsgen dnsrecon dnsx erlpopper exclude-cdn exec feroxbuster fff ffuf ffuz findomain gau gauplus github-endpoints github-subdomains gobuster gorgo gospider gowitness gxss hakrawler http2smugl httprobe httpx jaeles kiterunner linkfinder masscan massdns meg naabu nmap nmapx nuclei openredirex paramspider puredns rustscan s3scanner scrying shuffledns soxy sqlmap subfinder subjs testssl tlscout unimap wafw00f waybackurls webscreenshot whois & wpscan. Once installed and setup, you can distribute a scan of a large set of targets across 100-150 instances within minutes and get results extremely quickly. This is called [axiom-scan](https://github.com/pry0cc/axiom/wiki/Scans).

Axiom supports several cloud providers, eventually, axiom should be completely cloud agnostic allowing unified control of a wide variety of different cloud environments with ease. Currently, DigitalOcean, IBM Cloud, Linode and Azure are officially supported providers. Google Compute is partially implemented and AWS is on the roadmap. If you would like prioritization of a feature or provider implementation, please contact me @pry0cc on Twitter and we can discuss :)

# Resources

-   [Introduction](https://github.com/pry0cc/axiom/wiki)
-   [Troubleshooting & FAQ](https://github.com/pry0cc/axiom/wiki/0-Installation#troubleshooting)
-   [Quickstart](https://github.com/pry0cc/axiom/wiki/A-Quickstart-Guide)
    - [Fleets](https://github.com/pry0cc/axiom/wiki/Fleets)
    - [Scans](https://github.com/pry0cc/axiom/wiki/Scans)
-   [Demo](#demo)
-   [Story](https://github.com/pry0cc/axiom/wiki/The-Story)
-   [Installation Instructions](https://github.com/pry0cc/axiom#installation)
    -   [Docker Install](#docker)
    -   [Easy Install](#easy-install)
    -   [Manual Install](https://github.com/pry0cc/axiom/wiki/0-Installation#Manual)
-   [Scan Modules](https://github.com/pry0cc/axiom/wiki/Scans#example-axiom-scan-modules)
-   [Contributors](#contributors)

# Credit
The original and best supported provider for Axiom is Digital Ocean! If you're signing up for a new Digital Ocean account, [please use my link!](https://m.do.co/c/bd80643300bd) 

<p align="center">
<a href="https://m.do.co/c/bd80643300bd" target="_blank"> <img src="https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Referrals/digitalocean_referral.png"/></a></p>
  
Our third provider for axiom! Please use [this link](https://www.linode.com/?r=23ac507c0943da0c44ce1950fc7e41217802df90) for $20 free credit on Linode :) 
<p align="center">
<a href="https://www.linode.com/?r=23ac507c0943da0c44ce1950fc7e41217802df90" target="_blank"> <img src="https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Referrals/linode_referral.png"/></a></p>

<p align="center">
<a href="https://www.azure.com" target="_blank"> <img src="https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Referrals/azure_referral.png" screenshots/Referrals/azure_referral.png/></a></p>

<p align="center">
<a href="https://cloud.ibm.com" target="_blank"> <img src="https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/Referrals/ibm_cloud_referral.png" screenshots/Referrals/azure_referral.png/></a></p>

# Installation
## Docker
```
docker exec -it $(docker run -d -it ubuntu) sh -c "apt update && apt install git -y && git clone https://github.com/pry0cc/axiom ~/.axiom/ && cd && .axiom/interact/axiom-configure"
```

## Easy Install

You should use an OS that supports our [easy install](https://github.com/pry0cc/axiom#operating-systems-supported). <br>
For Linux systems you will also need to install the newest versions of all packages beforehand `sudo apt dist-upgrade`. <br>
```
bash <(curl -s https://raw.githubusercontent.com/pry0cc/axiom/master/interact/axiom-configure)
```

If you have any problems with this installer, or if using an unsupported OS please refer to [Installation](https://github.com/pry0cc/axiom/wiki/0-Installation).

# Demo
In this demo (sped up out of respect for your time ;) ), we show how easy it is to initialize and ssh into a new instance.

<img src="https://raw.githubusercontent.com/pry0cc/axiom/master/screenshots/axiom-init-demo.gif" alt="" height=443 width=666px>


# Sponsored By SecurityTrails!
<img src="https://securitytrails.com/images/logo.png" width=400px>
We are lucky enough to be sponsored by the awesome SecurityTrails! Sign up for your free account <a href="https://securitytrails.com/app/signup?utm_source=axiom">here!</a>

# Support
If you like Axiom and it saves you time, money or just brings you happy feelings, please show your support through sponsorship! Click the little sponsor button in the header and sponsor for as little as $1 per month :)

Or buy me a coffee to keep me powered :)

<a href="https://www.buymeacoffee.com/pry0cc" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-black.png" alt="Buy Me A Coffee" width=300px> </a>

---


## Operating Systems Supported
| OS         | Supported | Easy Install  | Tested        | 
|------------|-----------|---------------|---------------|
| Ubuntu     |    Yes    | Yes           | Ubuntu 20.04  |
| Kali       |    Yes    | Yes           | Kali 2021.3   |
| Debian     |    Yes    | Yes           | Debian 10     |
| Windows    |    Yes    | Yes           | WSL w/ Ubuntu |
| MacOS      |    Yes    | Yes           | MacOS 11.6    |
| Arch Linux |    Yes    | No            | Yes           |



# Contributors
We've had some really fantastic additions to axiom, great feedback through issues, and perseverence through our heavy beta phase!

A list of all contributors can be found [here](https://github.com/pry0cc/axiom/graphs/contributors), thank you all!

# Art
The [original logo](https://github.com/pry0cc/axiom/commit/9ab2cc30910cc39e1e9db325877530b4f3716e38) was made by our amazing [s0md3v](https://twitter.com/s0md3v)! Thank you for making axiom look sleek as hell! Really beats my homegrown logo :)

The awesome referral banners were inspired by [fleex](https://github.com/FleexSecurity/fleex) and were made by the one and only [xm1k3](https://twitter.com/xm1k3_)!

# Tools to Date

- [x]  Amass
- [x]  Arjun
- [x]  Corsy
- [x]  CrackMapExec
- [x]  DNSCewl
- [x]  Docker
- [x]  ERLPopper
- [x]  Gf-Patterns
- [x]  Go
- [x]  Gxss
- [x]  Interlace
- [x]  LinkFinder
- [x]  OpenRedireX
- [x]  ParamSpider
- [x]  RustScan
- [x]  SecLists
- [x]  Tools
- [x]  Wordlists
- [x]  aiodnsbrute
- [x]  anew
- [x]  anti-burl
- [x]  aquatone
- [x]  assetfinder
- [x]  cent
- [x]  cf-check
- [x]  chaos-client
- [x]  commix
- [x]  concurl
- [x]  crlfuzz
- [x]  dalfox
- [x]  dirdar
- [x]  dnsgen
- [x]  dnsrecon
- [x]  dnsvalidator
- [x]  dnsx
- [x]  exclude-cdn
- [x]  feroxbuster
- [x]  fff
- [x]  ffuf
- [x]  findomain-linux
- [x]  gau
- [x]  gauplus
- [x]  getJS
- [x]  gf
- [x]  github-endpoints
- [x]  gobuster
- [x]  google-chrome
- [x]  gorgo
- [x]  gospider
- [x]  gowitness
- [x]  gron
- [x]  hakrawler
- [x]  httprobe
- [x]  httpx
- [x]  interactsh-client
- [x]  jaeles
- [x]  kiterunner
- [x]  kxss
- [x]  leaky-paths
- [x]  masscan
- [x]  massdns
- [x]  medusa
- [x]  meg
- [x]  naabu
- [x]  nmap
- [x]  nuclei
- [x]  permutations
- [x]  phantomjs
- [x]  proxychains-ng
- [x]  puredns
- [x]  qsreplace
- [x]  resolvers
- [x]  responder
- [x]  s3scanner
- [x]  scrying
- [x]  shuffledns
- [x]  sn0int
- [x]  sqlmap
- [x]  subfinder
- [x]  subjack
- [x]  subjs
- [x]  testssl
- [x]  thc-hydra
- [x]  ufw
- [x]  unimap
- [x]  wafw00f
- [x]  waybackurls
- [x]  webscreenshot
- [x]  wpscan

And many more! Do you want to add a package to axiom? [Read the wiki!](https://github.com/pry0cc/axiom/wiki/Adding-Simple-Modules)
<p align="center">
<a href="https://github.com/pry0cc/axiom/wiki" target="_blank"> <img src="screenshots/Referrals/axiom_docs.png"/></a>
</p>
