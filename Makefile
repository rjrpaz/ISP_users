MYSQLUSER=root
MYSQLPASSWORD=4c0r4z4d0

PERL=/usr/bin/perl -wc

# Ubicacion de las paginas de Tickets
HTMLDIR=/usr/local/apache-root/usuarios
SCRIPTDIR=/usr/local/apache-root/usuarios
# perl -e 'print "@INC \n";'
PMDIR=/usr/local/lib/site_perl/i386-linux
WWWUSER=root
WWWGROUP=root

all: 
	/usr/bin/clear
	@echo
	$(PERL) usuarios.pm
	@echo
	$(PERL) usuarios.html
	@echo
	$(PERL) usuarios_sabana.html
	@echo
	$(PERL) usuarios_clave.html
	@echo

#crypt: crypt.c
#	cc -o crypt crypt.c -lcrypt

install:
	install -m 700 -D -o $(WWWUSER) -g $(WWWGROUP) usuarios.pm $(PMDIR)/usuarios.pm
	install -m 700 -D -o $(WWWUSER) -g $(WWWGROUP) usuarios.html $(SCRIPTDIR)/usuarios.html
	install -m 700 -D -o $(WWWUSER) -g $(WWWGROUP) usuarios_sabana.html $(SCRIPTDIR)/usuarios_sabana.html
	rm -f $(SCRIPTDIR)/usuarios_sabana.pdf
	rm -f $(SCRIPTDIR)/usuarios_sabana.xls
	cd $(SCRIPTDIR);ln -s usuarios_sabana.html usuarios_sabana.pdf;ln -s usuarios_sabana.html usuarios_sabana.xls
	install -m 700 -D -o $(WWWUSER) -g $(WWWGROUP) usuarios_clave.html $(SCRIPTDIR)/usuarios_clave.html
#	install -m 700 -D -o root -g root crypt /bin/crypt

