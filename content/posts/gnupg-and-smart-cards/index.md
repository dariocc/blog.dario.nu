---
title: "Using GnuPG with a smart card"
date: 2020-09-20T22:00:00+02:00
draft: false
tags: [gpg, ssh, pgp]
languages: [en]
---

## title: "Using GnuPG with a smart card" date: 2020-09-20T22:00:00+02:00 draft: false tags: \[gpg, ssh, pgp\] languages: \[en\]

# GnuPG & smart cards

GnuPG supports the use of OpenPGP smart cards: hardware devices with the ability
to store the private key of PGP key-pairs and use them during cryptographic
operations.

Storing private keys in a smart card is considerably more secure than storing
them in your computer given that you reduce the surface of attack: an smart card
is not connected to internet as your computer is, nor is subject to spoofing
attacks or can be subject to OS vulnerabilities.

OpenPGP smart cards have a number of characteristics that make them the perfect
media to store private keys. Namely:

- The keys never leaves the smart card device. Once written private keys cannot
  be externally accessed. No one will be able to make a copy of your key.

- Cryptographic operations occur inside the smart card device, i.e. the *maths*
  is happening inside the card.

- The private information stored in the key is protected by a pin-code with a
  limited number of retry attempts. After a number of unsuccessful pin
  introduction the secret information contained in the card is destroyed.

- Smart card devices are designed to be tamper-proof. Even when an unauthorized
  person has access to the physical device, she won’t be able to access the
  secrets inside it.

Having keys stored in a smart card device has also the benefit of portability:
you can take your keys with you and use them safely in whichever computer you
need to do. Some of the cards offer NFC capabilities which make it easy to use
with a smart-phone.

In short using a OpenPGP smart card is both more secure and more convenient than
storing private keys in your computer.

# Using OpenPGP smart cards in GnuPG and Linux

First, we’ll need the `pcscd` tool, which is a daemon that applications such as
GnuPG use to communicate with smart cards readers.

In my test setup I’m using Fedora 32 and that tool is provided by the
`pcsc-lite` package. We will install also the `pcsc-tools` which provides the
`pcsc_scan` utility that will use shortly:

```
sudo dnf install pcsc-lite pcsc-tools
```

Several manufacturers produce OpenPGP SmartCard devices and they may be sold in
a card-form factor (similar to a credit card) or as a USB hardware device. For
this test I’m using a YubiKey 5.

Whichever the type of smart card you are using, insert it in your computer and
run the `pcsc_scan` application. In my case I got the following:

```
Reader 0: Alcor Micro AU9560 00 00
  Event number: 0
  Card state: Card removed,
Reader 1: Yubico YubiKey CCID 01 00
 Event number: 0
 Card state: Card inserted,
```

This tells me that I have two smart card reader ports. The first one corresponds
to the reader integrated in my computer, the second one to the YubiKey. Take
note of the smart card Reader name that you’ll be using, we will use it soon.

I’m assuming you have GnuPG installed. Version 2.2.0 was used for writing this
article. Some systems might have both GnuPG 1.x and GnuPG 2.x installed and have
two different binaries `gpg` and `gpg2`, but in my distribution both names refer
to the same GnuPG version 2 software.

Edit or create the `scdaemon.conf` file in your GnuPG home directory
(`~/.gnupg/scdaemon.conf by default`), and append the name of the reader you’ll
be using. Since I didn’t have the file, I simply did:

```
echo "reader-port Yubico Yubi" > ~/.gnupg/scdaemon.conf
```

Notice that we don’t specify the full text we saw when invoking the `pcsc_scan`
command. The `CCID 01 00` part of the string is variable and depends on the
configuration and number of YubiKeys you have inserted.

Now you can run `gpg --card-status`:

```
Reader ...........: Yubico YubiKey CCID 01 00
Application ID ...: D2....................
Application type .: OpenPGP
Version ..........: 3.4
Manufacturer .....: Yubico
Serial number ....: 13.....
Name of cardholder: [not set]
Language prefs ...: [not set]
Salutation .......:
URL of public key : [not set]
Login data .......: [not set]
Signature PIN ....: not forced
Key attributes ...: rsa2048 rsa2048 rsa2048
Max. PIN lengths .: 127 127 127
PIN retry counter : 3 0 3
Signature counter : 0
KDF setting ......: off
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]
```

You are ready to go!

# Configuring PIN, admin PIN and key attributes of an OpenPGP smart card

There are a few preparatory actions you should consider when operating with a
new smart card, namely:

1. Configure the PIN.

1. Configure a admin PIN.

1. Configuring key attributes.

These can configured by using the `gpg --card-edit` command. When you run the
command, you’ll see the same information that was output by the previous
`gpg --card-status`, just in this case you’ll be in the `gpg/card` interactive
console. Executing *help* lists the available commands:

```
gpg/card> help
quit           quit this menu
admin          show admin commands
help           show this help
list           list all available data
fetch          fetch the key specified in the card URL
passwd         menu to change or unblock the PIN
verify         verify the PIN and list all data
unblock        unblock the PIN using a Reset Code
```

The PIN is a passphrase that you will be prompted to enter during
sign/encryption/authentication operations. It is your every-day-use PIN. If you
provide 3 consecutive wrong PINs, the user functionality becomes blocked.

The admin PIN allows you to do additional card configuration such as the key
attributes, ublock or reset PIN, trigger the generation of new keys and other.

To configure the PIN we’ll toggle first admin commands by running `admin` and
then use the `passwd` command:

```
gpg/card> passwd
gpg: OpenPGP card no. D2760000..... detected

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit
```

Pick the option of your choice and follow the steps. If you wonder what the
fourth option does, I do too. I believe it should be a way to set-up a reset
code for ublocking PIN without the need of the Admin PIN, but I tried to make it
work and I couldn’t, so I’ll leave that for future investigation.

Once you’ve set-up PIN and admin PIN you might want to change the default key
attributes. These refer to the type of algorithm used to generate the key
(RSA/ECC) and the keysize.

RSA with keys of 2048bits is considered a good default choice. Increasing the
keysize makes it more resilient to certain types of attacks at the cost of
slower cryptographic operations. My choice is in this case RSA 4096, it should
be noted though that not all smart cards support keysizes of more than 2048bits.
The YubiKey 5 series does however.

# Limitations of OpenPGP smart cards

A OpenPGP smart card has 3 slots for storing private keys. Remember the output
of the `gpg --card-status` command. It contained following lines:

```
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
```

The three slots are named *signature*, *encryption* or *authentication*.
Normally you create keypairs with defined capabilities and it is quite common,
for security reasons, to separate the keypairs that are used for *signing*,
*encrypting* and *authenticating*.

Another important characteristic is the fact that an OpenPGP smart card only
stores private keys and nothing more. Public keys, uuids and additional
information associated to your gpg key won’t be stored in the smart card.

Make sure you don’t loose access to the public keys associated to your private
keys. Publish them to a public server or export them and have them stored
somewhere else.

A real world analogy is finding bycicle lock keys in the street: they are
useless unless you know which lock they are used with. Your public gpg
information is the lock and the private keys are the key you found.

# Generating vs Importing keys

While this article doesn’t cover how to generate keypairs it is of relevance to
mention that when working with keys and smart card devices you will have to
decide between generating your keys inside the card or generating them
externally and importing them into the card.

The advantage of the first option is that you have guarantee that your key will
never leave the card. The disadvantage is though that precisely because of that
property, you won’t be able to back-up your key, which is normally undesirable
because otherwise loosing your smart card device would leave you without any of
your private keys.

In contrast, generating the keys externally gives you the chance to import it in
as many devices as you want and comes at the cost of increasing the surface of a
possible private key stealing attack.

Normally you can have a good-enough guarantees this won’t happen by executing
the key-generation process in a live linux distribution, making sure the
computer you are using is disconnected from the network and carrying out the
activity in a *trusted environment* such as your home.

Depending on the use you do of your keypairs, losing private keys might be a
lesser or bigger concern to you depending on the use you do of them, but in the
most general case you’ll want to have them backed up.

One last aspect to notice, when using `gpg --card-edit` to generate keys inside
the card you’ll be asked to *make an off-card backup of encryption key*:

```
gpg/card> generate
Make off-card backup of encryption key? (Y/n)
```

If you answer yes, GnuPG will not generate the key inside the card, but will do
it outside and then import it into the smart card. The private key will be
placed in your GnuPG home directory, typically `~/.gnupg`.

My preferred choice is to generate the key outside and then import it to the
smart card. This makes me more concious of what I’m doing and gives every smart
card the same treatment: the operations I execute against each card are exactly
the same.

# Importing keys into a OpenPGP smart card

The process of importing a key into a smart card is relatively simple:

1. Edit the GPG key.

1. Select the key you want to import into the card.

1. Use `keytocard`.

For example, assume we have one gpg key with 3 subkeys, one for signing and two
for authentication. The `gpg --list-secret-keys` command would list something
like this:

```
sec   rsa4096 2020-09-20 [C] [expires: 2021-09-20]
      B5C3B6D2D7CF2B98A86C6BEEEF66B14C1C6C1733
uid           [ultimate] Foo Bar <foo@bar.com>
ssb   rsa4096 2020-09-20 [S] [expires: 2021-03-19]
ssb   rsa4096 2020-09-20 [A] [expires: 2021-03-19]
ssb   rsa2048 2020-09-20 [A] [expires: 2020-12-19]
```

We decide to move one of the authentication sub-keys to the card, for example
the one encoded with `rsa4096`.

Use `gpg --edit-card` to enter into the card edition menu:

```
gpg --edit-card foo@bar.com
```

Select the key to be sent to the card (notice the asterisk after *ssb*):

```
gpg> key 2

...
ssb* rsa4096/230F084A0E3C76C5
created: 2020-09-20  expires: 2021-03-19  usage: A
...
```

Then use `keytocard` and follow instructions. You’ll be asked first to provide
the passphrase to unlock the private key and then you’ll need to provide the
*admin PIN* to be able to write the key into the card.

Repeat the procedure for any other keys that you want to import into the smart
card device. Remember you can only import 3 keys (one for certification/signing,
one for encryption, one for authentication).

You may now use `quit` or `save`. If you *quit*, your changes in the local
keyring will be discarded. This is useful if you plan to program other cards
with the same private key. If you use *save* instead your local keyring key will
be deleted.

having the same private keys in multiple keys can make sense for example if you
want to have some *ready to use backup’s*, but using the two keys in the same
machine is less practical than one would wish. When you first use the private
keys of one of your smart card GnuPG will remember the card you used and you
will be asked for it next time the private keys are needed and providing an
alternative card won’t work. You can of course use `gpg --delete-secret-keys`,
but probably not something you want to be doing if you’ll be regularly using
both cards from the same machine. There are ways to circumvent this, as
explained in a
[Stack Overflow post](https://security.stackexchange.com/questions/165286/how-to-use-multiple-smart-cards-with-gnupg).

For the shake of this article, let’s assume you used `save` after you imported
your private keys into your last smart card.

If you run again `gpg --list-secret-keys` you’ll notice that subkeys that have
been moved to the smart card will be marked with a `>` character:

```
sec   rsa4096 2020-09-20 [C] [expires: 2021-09-20]
      B5C3B6D2D7CF2B98A86C6BEEEF66B14C1C6C1733
uid           [ultimate] Foo Bar <foo@bar.com>
ssb   rsa4096 2020-09-20 [S] [expires: 2021-03-19]
ssb>  rsa4096 2020-09-20 [A] [expires: 2021-03-19]
ssb   rsa2048 2020-09-20 [A] [expires: 2020-12-19]
```

You can confirm the keys are in the card by running `gpg --card-status`.

# SSH authentication with OpenPGP

One of the useful uses of GPG is to authenticate against SSH servers. In
combination with the ability of having your private keys in OpenPGP smart card
becomes very convenient because you do no longer have to manage multiple ssh
keypairs for multiple computers.

This section assumes you have a GPG sub-key with authentication capability
associated to your gpg key. Nothing is specific to working with a smart card,
just the reason for using gpg-agent for SSH authentication dissipates a bit if
you don’t have a convenient way of transporting your key.

The steps are:

1. Add the key-grip of the authentication subkey you intend to use to the
   `sshcontrol` file.

1. Configure `SSH_AUTH_SOCK` to point to the gpg-ssh-agent socket path.

1. Restart gpg-agent.

1. Export your public authentication subkey in SSH format.

We need to determine the *key-grip* of our authentication subkey. In GnuPG keys
can be identify by a number of ids, key-grip is just one of those identifying
strings, a protocol-agnostic one, which has the particularity of not being
calculated from any information which is only specific to GnuPG (thus
protocol-agnostic).

Use `gpg --list-keys --with-keygrip foo@bar.com` to get the *key-grip* of a
`foo@bar.com` key in your keyring:

```
gpg --list-secret-keys --with-keygrip foo@bar.com
sec   rsa4096 2020-09-20 [SC] [expires: 2021-09-20]
      B5C3B6D2D7CF2B98A86C6BEEEF66B14C1C6C1733
      Keygrip = 1626B365C9613BD2044E38EA8B7742385A253343
      Card serial no. = 0006 13050706
uid           [ultimate] Foo Bar <foo@bar.com>
ssb   rsa4096 2020-09-20 [S] [expires: 2021-03-19]
      Keygrip = 1A46E96BC2865EEBAA3797AA2C3CF042AB8654A1
ssb>  rsa4096 2020-09-20 [A] [expires: 2021-03-19]        <-- This one
      Keygrip = 5A833DA4CE9302EB7E67905C90D4E85083BD36AC
...
```

Take note of your authentication subkey key-grip and add it to the
`~/.gnupg/sshcontrol` file:

```
echo "5A833DA4CE9302EB7E67905C90D4E85083BD36AC" >> `~/.gnupg/sshcontrol`
```

Now we need to configure OpenSSH to use a different agent thatn the usual
`ssh-agent`. This is achieved by setting `SSH_AUTH_SOCK` to the path of the
gpg-agent socket. You can use the following:

```
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
```

Kill gpg-agent:

```
gpgconf --kill gpg-agent
```

And launch it again:

```
gpgconf --launch gpg-agent
```

To export key, first find out the fingerprint of your authentication subkey:

```
gpg --list-keys --with-subkeys-fingerprint foo@bar.com
   pub   rsa4096 2020-09-20 [SC] [expires: 2021-09-20]
         B5C3B6D2D7CF2B98A86C6BEEEF66B14C1C6C1733
         uid           [ultimate] Foo Bar <foo@bar.com>
   sub   rsa4096 2020-09-20 [S] [expires: 2021-03-19]
         DD0E8241A9017BC6EE07E64060899F380F3B935E
   sub   rsa4096 2020-09-20 [A] [expires: 2021-03-19]   <-- This one
         DC947A18DC5C0CB81C8FAF04230F084A0E3C76C5
   ...
```

Then use `--export-ssh-key` to export the authentication key public key in a SSH
compatible format.

```
gpg -o id_rsa --export-ssh-key DC947A18DC5C0CB81C8FAF04230F084A0E3C76C5!
```

Pay attention to the `!` sign. It indicates that you want to export this and
only this sub-key.

Now treat `id_rsa` as you would with any other SSH public key, i.e. publish it
to the servers you want to access, upload it to Github, etc.

Of course, the changes you’ve done to `SSH_AUTH_SOCK` aren’t permanent. Add them
to your `.bashrc` (or alternative shell start-up script) as needed.

Congratulations! You now know how to to use an OpenPGP smart card for ssh
authentication!

# Closing

We’ve seen the conveniency of storing GPG private keys in an OpenPGP smart card
and the associated security benefits. We’ve learned how to configure GnuPG to
make use of it and how to import keys in it. We saw how to configure OpenSSH to
use authentication subkeys of GnuPG.

GnuPG takes time to learn so don’t be disencouraged. Hopefully you found this
article helpful. If you have questions feel free to
[contact me](../../about/index.xml).
