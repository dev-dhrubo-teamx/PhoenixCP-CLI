# 🐦‍🔥 PhoenixCP CLI

**PhoenixCP CLI** is a lightweight, systemd-free, menu-based CLI control panel  
designed for low-resource VPS environments.

> **Rise • Control • Deploy**

Built for developers who want:
- No heavy web panels
- No systemd dependency
- Full control with minimal RAM usage

---

## ✨ Features

- ✅ Menu-based interactive CLI
- ✅ Multi-website hosting (Nginx + PHP-FPM)
- ✅ MySQL / MariaDB support
- ✅ Cloudflare Tunnel integration
- ✅ SSL support (Cloudflare Origin SSL)
- ✅ SSL status check per website
- ✅ Create / Delete websites
- ✅ Auto create MySQL database & user
- ✅ Advanced service status dashboard
- ✅ 1 GB RAM friendly
- ❌ No heavy Web UI
- ❌ No systemd required

---

## 📦 System Requirements

- OS: **Ubuntu 20.04 / 22.04 / 24.04**
- CPU: 1 Core (2 recommended)
- RAM: **1 GB minimum**
- Root access required

---

## 🚀 1-Click Installation

Run the following command on your VPS:

# Install Command
```bash
curl -fsSL https://raw.githubusercontent.com/dev-dhrubo-teamx/PhoenixCP-CLI/main/phoenix.sh | bash
```
# Uninstall Command
```bash
curl -fsSL https://raw.githubusercontent.com/dev-dhrubo-teamx/PhoenixCP-CLI/main/uninstall.sh | bash
```
# Others Command If Necessary Need

Vps web Browser SSH Access TTYD Method
```bash
apt update
apt install -y ttyd
```
This run ttyyd :
```
ttyd -p 7681 bash
```
👉 Browser :
```
http://SERVER_IP:7681
```
# Gdown Install clean ও reliable Method
```
apt update
apt install -y python3-pip
pip3 install gdown
```
# If Come Default Apache Page 
```
a2dissite 000-default.conf
a2dissite default-ssl.conf
apachectl -k graceful
```
# Tiny Default User 

username : admin
pass : admin@123

# Phpmyadmin Default User :

user: root
pass : root

# Website Match or Redirect  Same Domain

1 
```
echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername
apachectl -k graceful
```
2
```
cat > /etc/apache2/sites-available/000-catchall.conf <<EOF
<VirtualHost *:80>
  ServerName _
  DocumentRoot /var/www/_invalid

  <Directory /var/www/_invalid>
    Require all denied
  </Directory>
</VirtualHost>
EOF
```
3
```
apachectl -k graceful
```
# Php Ini Update Mysql Upload Limit 

1. 
```
php -v
php --ini
```
2.
```
nano /etc/php/8.1/fpm/php.ini
```
3.
```
sudo systemctl restart php8.1-fpm
```
# Sql Stric Mode Disable
1.
```
mysql -u root -p
```
2.
```
SET GLOBAL sql_mode='';
```
3.
```
SELECT @@GLOBAL.sql_mode;
```
# Backup & ZIP
```
apt install -y pigz
apt install -y pv
```
```
tar -cf - public_html | pv > public_html.tar
```
<h2>🔒 Fix: Cloudflare Tunnel + WordPress ERR_TOO_MANY_REDIRECTS</h2>

<p>
This guide fixes infinite redirect loops when running a WordPress site
behind <strong>Cloudflare Tunnel (cloudflared)</strong>.
</p>

<hr>

<h3>✅ Step 1: Cloudflare-aware HTTPS fix (MUST DO)</h3>

<p>Edit <code>wp-config.php</code>:</p>

<pre><code>nano /var/www/html/wp-config.php</code></pre>

<p>
Add the following code <strong>before</strong> the line:<br>
<code>/* That's all, stop editing! */</code>
</p>

<pre><code>
// Cloudflare Tunnel HTTPS fix
if (
    isset($_SERVER['HTTP_X_FORWARDED_PROTO']) &&
    $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https'
) {
    $_SERVER['HTTPS'] = 'on';
}
</code></pre>

<hr>

<h3>✅ Step 2: Force WordPress Site URL (Very Important)</h3>

<p>
Add these lines in the same <code>wp-config.php</code> file:
</p>

<pre><code>
define('WP_HOME', 'https://plxbd.baby');
define('WP_SITEURL', 'https://plxbd.baby');
</code></pre>

<p>
<strong>Why?</strong><br>
When using Cloudflare Tunnel, WordPress may mis-detect the scheme (HTTP/HTTPS).
Overriding URLs in <code>wp-config.php</code> is the safest solution.
</p>

<hr>

<h3>✅ Step 3: Remove HTTPS Redirects from .htaccess</h3>

<p>
Cloudflare already handles HTTPS. Any extra redirect will cause a loop.
</p>

<pre><code>nano /var/www/html/.htaccess</code></pre>

<p>
❌ If you see this block, <strong>DELETE it</strong>:
</p>

<pre><code>
RewriteCond %{HTTPS} off
RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</code></pre>

<p>
⚠️ Keeping this rule will cause <code>ERR_TOO_MANY_REDIRECTS</code>.
</p>

<hr>

<h3>✅ Step 4: Cloudflare Dashboard Settings (Critical)</h3>

<p><strong>Cloudflare → SSL/TLS → Overview</strong></p>

<ul>
  <li>Encryption Mode: <strong>Full</strong></li>
  <li>❌ Flexible (Never use)</li>
</ul>

<p><strong>Cloudflare → SSL/TLS → Edge Certificates</strong></p>

<ul>
  <li>❌ Always Use HTTPS → OFF</li>
  <li>❌ Automatic HTTPS Rewrites → OFF (at least for testing)</li>
</ul>

<hr>

<h3>✅ Step 5: Disable HTTPS Forcing in Control Panel</h3>

<p>If you are using a mini panel or hosting panel:</p>

<ul>
  <li>❌ Force HTTPS → OFF</li>
  <li>❌ Redirect HTTP to HTTPS → OFF</li>
</ul>

<p>
Cloudflare Tunnel already provides HTTPS — do not duplicate it.
</p>

<hr>

<h3>🧪 Step 6: Test</h3>

<ol>
  <li>Open an Incognito / Private browser window</li>
  <li>Visit: <code>https://plxbd.baby</code></li>
  <li>If it opens correctly → success ✅</li>
  <li>Re-enable WordPress plugins one by one</li>
</ol>

<hr>

<h3>✅ Minimal Required Fix (TL;DR)</h3>

<p>
If you only want the essentials, this is enough:
</p>

<pre><code>
// Cloudflare Tunnel HTTPS fix
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) &&
    $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

define('WP_HOME', 'https://plxbd.baby');
define('WP_SITEURL', 'https://plxbd.baby');
</code></pre>

<p>
And make sure there is <strong>no HTTPS redirect</strong> in <code>.htaccess</code>.
</p>

<hr>

<h3>🔐 Bonus: Secure Admin & REST API</h3>

<pre><code>
define('FORCE_SSL_ADMIN', true);
</code></pre>

<p>
This prevents login and REST API issues when running behind Cloudflare Tunnel.
</p>
<h2>📦 Enable PHP Extensions: <code>intl</code> & <code>bcmath</code> (PHP 8.1)</h2>

<p>
This guide explains how to enable the required PHP extensions
<strong>intl</strong> and <strong>bcmath</strong> for WordPress or PHP scripts
running on <strong>Apache + PHP-FPM</strong>.
</p>

<hr>

<h3>❓ Why these extensions are required</h3>
<ul>
  <li><strong>intl</strong> — locale, language, currency, and date handling</li>
  <li><strong>bcmath</strong> — high-precision mathematical calculations</li>
</ul>

<p>You may see errors like:</p>

<pre><code>
You must enable the intl extension to use the script.
You must enable the bcmath extension to use the script.
</code></pre>

<hr>

<h3>✅ Step 1: Install required packages</h3>

<pre><code>
apt update
apt install -y php8.1-intl php8.1-bcmath
</code></pre>

<p><em>Safe to run even if already installed.</em></p>

<hr>

<h3>✅ Step 2: Enable extensions for PHP-FPM</h3>

<p>Check if enabled:</p>

<pre><code>
ls /etc/php/8.1/fpm/conf.d | grep -E "intl|bcmath"
</code></pre>

<p>If not found, enable manually:</p>

<pre><code>
ln -s /etc/php/8.1/mods-available/intl.ini /etc/php/8.1/fpm/conf.d/20-intl.ini
ln -s /etc/php/8.1/mods-available/bcmath.ini /etc/php/8.1/fpm/conf.d/20-bcmath.ini
</code></pre>

<hr>

<h3>🔄 Step 3: Restart services</h3>

<pre><code>
service php8.1-fpm restart
service apache2 restart
</code></pre>

<hr>

<h3>🧪 Step 4: Verify (Web)</h3>

<pre><code>
echo "&lt;?php phpinfo(); ?&gt;" &gt; /var/www/html/info.php
</code></pre>

<p>Open in browser:</p>
<pre><code>https://your-domain/info.php</code></pre>

<p>Search for <strong>intl</strong> and <strong>bcmath</strong>.</p>

<hr>

<h3>⚠ Important notes</h3>
<ul>
  <li>CLI PHP uses <code>/etc/php/8.1/cli</code></li>
  <li>Web PHP (Apache + FPM) uses <code>/etc/php/8.1/fpm</code></li>
  <li>CLI extensions do <strong>not</strong> affect the website</li>
</ul>

<hr>

<p><strong>Maintained by:</strong> TeamX-Dev-Dhrubo</p>
