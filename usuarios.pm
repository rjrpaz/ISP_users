package usuarios;

use strict;

require Exporter;
require Mysql;
require freeradius;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION     = 0.01;

@ISA         = qw(Exporter Mysql freeradius);
@EXPORT      = qw(&chequeo_password_radius_para_usuarios &chequeo_password_so_para_usuarios &cambio_contrasena_radius &cambio_contrasena_so &cambio_contrasena_ftp &menu_usuarios_sabana $server $tamanio_minimo_contrasenia $host $database $dbuser $dbpass);

%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

@EXPORT_OK   = qw();
use vars qw($server $tamanio_minimo_contrasenia $host $database $dbuser $dbpass $mail_only_rules_name $radius_fecha_inicial @tipo_de_iva);

use vars qw(@parametro $sql_statement $sth $dbh $radwho $checkrad $naslist);

$server = "http://server.micasa.org:443";
#$server = "https://radius.tvicom.com.ar";
$tamanio_minimo_contrasenia = 4;
$host = "localhost";
$database = "radius";
$dbuser = "nobody";
$dbpass = "nobody";
my %OIDS = ();

sub chequeo_password_radius_para_usuarios
{
	my $database = "radius";
	my $table = "radcheck";
	my $password = "";
	my $errmsg = "";

	local (@parametro) = @_;
	if ($parametro[0] eq "")
	{
		return 0;
	}

	$dbh = Mysql->connect($host, $database, $dbuser, $dbpass);
	$errmsg = Mysql->errmsg();

	if ($errmsg ne "")
	{
		&return_error_mysql ("Error en el proceso", "Existi&oacute; un error al intentarse la conexi&oacute;n con la Base de Datos.<BR>Consulte al Administrador de la misma.", $errmsg);
	}

	$sql_statement = "SELECT Value FROM $table WHERE (UserName like '".$parametro[0]."' AND Attribute like 'Password')";
	$sth = $dbh->query($sql_statement)
	or die &return_error_mysql ("Error en el proceso", "Hubo un error al Intentar obtener la palabra clave de la Base de Datos.<BR>Consulte al Administrador de la misma.", "");
	$password = $sth ->fetchrow;

	if ($parametro[1] eq $password)
	{
		return 1;
	}
	return 0;
}


sub chequeo_password_so_para_usuarios
{
	use Crypt::PasswdMD5;
	my $password = "";
	my $password_shadow = "";
	my $salt = "";
	my $crypted_pass = "";

	local (@parametro) = @_;
	my $user = $parametro[0];
	my $pass = $parametro[1];
	if (($user eq "") || ($pass eq ""))
	{
		return 0;
	}

	$password_shadow = `/bin/grep ^$user: /etc/shadow | /usr/bin/cut -d: -f2`;
	if ($password_shadow eq "")
	{
		return 0;
	}
	($password_shadow) = ($password_shadow =~ /([^\n]*)/);

	($salt) = ($password_shadow =~ /(.{11})/);
	$crypted_pass = unix_md5_crypt($pass, $salt);
	if ($password_shadow eq $crypted_pass)
	{
		return 1;
	}
	return 0;
}


sub cambio_contrasena_radius
{
	my $table = "radcheck";
	local (@parametro) = @_;
	$dbh = Mysql->connect($host, $database, $dbuser, $dbpass);

	$sql_statement = "UPDATE $table SET Value =  '".$parametro[1]."' WHERE (UserName LIKE '".$parametro[0]."' AND Attribute LIKE 'Password')";

	$dbh->query($sql_statement)
	or die &return_error_mysql ("Error en el proceso", "Hubo un error en la consulta a la Base de Datos.<BR>Consulte al Administrador de la misma.", $dbh->errmsg());
}


sub cambio_contrasena_so
{
	my $comando = "";
	my $usuario = "";
	my $password = "";
	my $crypted_password = "";
	my $usuario_existe = 0;

	local (@parametro) = @_;

	$usuario = $parametro[0];
	$password = $parametro[1];

	my $username = (getpwnam($usuario))[0];
	if ($username eq $usuario)
	{
		$usuario_existe = 1;
	}

	$crypted_password = `/bin/crypt $password`;
	$crypted_password =~ s/\$/\\\$/g;

	if ($usuario_existe)
	{
		$comando = "/usr/sbin/usermod -g internet -p \"$crypted_password\" -d /home/$usuario -s /bin/false -m $usuario";
	}
	system ($comando);
}


sub cambio_contrasena_ftp
{
	my $ftp_database = "proftpd";
	my $table = "users";
	my $uid = "";
	my $gid = "";
	my $homedir = "";
	my $comando = "";
	my $crypted_password = "";

	local (@parametro) = @_;

	my $usuario = $parametro[0];

	$dbh = Mysql->connect($host, $ftp_database, $dbuser, $dbpass);

	$comando = "grep \"^".$usuario.":\" /etc/shadow | cut -d: -f2";
	$crypted_password = `$comando`;
	($crypted_password) = ($crypted_password =~ /([^\n]*)/);

	$sql_statement = "UPDATE $table SET password =  '".$crypted_password."' WHERE (userid LIKE '".$usuario."')";
	$dbh->query($sql_statement)
	or die &return_error_mysql ("Error en el proceso", "Hubo un error en la consulta a la Base de Datos.<BR>Consulte al Administrador de la misma.", $dbh->errmsg());
}


sub menu_usuarios_sabana
{
	my $contador = "0";
	my $resultado = "";
	my $i = "0";
	my $dia = "";
	my $mes = "";
	my @anios = ();
	my $anios = "";
	my $anio_inicial = "";
	my $dia_final = "";
	my $mes_final = "";
	my $anio_final = "";

	local (@parametro) = @_;

	$resultado = `/bin/date +%y%m%d`;
	($anio_final) = ($resultado =~ /(.{2})/);
	($mes_final) = ($resultado =~ /.{2}(.{2})/);
	($dia_final) = ($resultado =~ /.{4}(.{2})/);

	($anio_inicial) = ($radius_fecha_inicial =~ /.{2}(.{2})/);

	if ($parametro[0] eq "")
	{
		$parametro[0] = "1";
	}
	if ($parametro[1] eq "")
	{
		$parametro[1] = $mes_final;
	}
	if ($parametro[2] eq "")
	{
		$parametro[2] = $anio_final;
	}
	if ($parametro[3] eq "")
	{
		$parametro[3] = $dia_final;
	}
	if ($parametro[4] eq "")
	{
		$parametro[4] = $mes_final;
	}
	if ($parametro[5] eq "")
	{
		$parametro[5] = $anio_final;
	}

	print "   <TABLE COOL BORDER=\"0\" CELLPADDING=\"0\" CELLSPACING=\"0\" ALIGN=\"center\">\n";
	print "    <tr height=\"20\">\n";
	print "     <td align=\"left\" colspan=\"3\" height=\"20\">\n";
	print "      &nbsp;\n";
	print "     </td>\n";
	print "    </tr>\n";

	print "    <TR bgcolor=\"#ffebcd\">\n";
	print "     <TD ALIGN=\"left\" COLSPAN=\"3\">\n";
	print "      <div ALIGN=\"center\">\n";
	print "       &nbsp;\n";
	print "       <font face=\"Arial, Helvetica, Geneva, Swiss, SunSans-Regular\" size=\"3\">\n";
	print "        <B>\n";
	print "         Desde:\n";
	print "        </B>\n";
	print "       </FONT>\n";
	print "      </div>\n";
	print "     </TD>\n";
	print "    </TR>\n";

	$contador = 0;
	$i = $anio_inicial;
	while ($i <= $anio_final)
	{
		$anios[$contador] = sprintf("%02d",$i);
		$i++;
		$contador++;
	}
	print "    <TR bgcolor=\"#ffebcd\">\n";
	print "     <TD ALIGN=\"left\" WIDTH=\"150\" nowrap>\n";
	print "      <div ALIGN=\"center\">\n";
	print "       <b>\n";
	print "        <font face=\"Arial, Helvetica, Geneva, Swiss, SunSans-Regular\" size=\"3\">\n";
	print "         Dia: \n";
	print "        </FONT>\n";
	print "        <font face=\"Courier New, Courier, Monaco\" size=\"3\">\n";
	print "         <SELECT NAME=\"dia_inicial\">\n";
	for ($i=1; $i<32; $i++)
	{
		$dia=sprintf("%02d", $i);
		print "           <OPTION";
		if ($dia eq $parametro[0])
		{
			print " SELECTED";
		}
		print ">$dia\n";
	}
	print "         </SELECT>\n";
	print "        </FONT>\n";
	print "       </b>\n";
	print "      </div>\n";
	print "     </TD>\n";

	print "     <TD ALIGN=\"left\" valign=\"middle\" WIDTH=\"150\" nowrap>\n";
	print "      <div ALIGN=\"center\">\n";
	print "       <b>\n";
	print "        <font face=\"Arial, Helvetica, Geneva, Swiss, SunSans-Regular\" size=\"3\">\n";
	print "         Mes: \n";
	print "        </FONT>\n";
	print "        <font face=\"Courier New, Courier, Monaco\" size=\"3\">\n";
	print "         <SELECT NAME=\"mes_inicial\">\n";
	for ($i=1; $i<13; $i++)
	{
		$mes=sprintf("%02d", $i);
		print "           <OPTION";
		if ($mes eq $parametro[1])
		{
			print " SELECTED";
		}
		print ">$mes\n";
	}
	print "         </SELECT>\n";
	print "        </FONT>\n";
	print "       </b>\n";
	print "      </div>\n";
	print "     </TD>\n";

	print "     <TD ALIGN=\"left\" valign=\"center\" WIDTH=\"200\" nowrap>\n";
	print "      <div ALIGN=\"center\">\n";
	print "       <b>\n";
	print "        <font face=\"Arial, Helvetica, Geneva, Swiss, SunSans-Regular\" size=\"3\">\n";
	print "         A&ntilde;o:\n";
	print "        </FONT>\n";
	print "        <font face=\"Courier New, Courier, Monaco\" size=\"3\">\n";
	print "         <SELECT NAME=\"anio_inicial\">\n";
	foreach $anios (@anios)
	{
		print "           <OPTION";
		if ($anios eq $parametro[2])
		{
			print " SELECTED";
		}
		print ">20".$anios."\n";
	}
	print "         </SELECT>\n";
	print "        </FONT>\n";
	print "       </b>\n";
	print "      </div>\n";
	print "     </TD>\n";
	print "    </TR>\n";

	print "    <tr height=\"20\">\n";
	print "     <td colspan=\"3\" height=\"20\">\n";
	print "      &nbsp;\n";
	print "     </td>\n";
	print "    </tr>\n";

	print "    <TR bgcolor=\"#ffebcd\">\n";
	print "     <TD COLSPAN=\"3\">\n";
	print "      <div ALIGN=\"center\">\n";
	print "       &nbsp;\n";
	print "       <font face=\"Arial, Helvetica, Geneva, Swiss, SunSans-Regular\" size=\"3\">\n";
	print "        <B>\n";
	print "         Hasta:\n";
	print "        </B>\n";
	print "       </FONT>\n";
	print "      </div>\n";
	print "     </TD>\n";
	print "    </TR>\n";

	print "    <TR bgcolor=\"#ffebcd\">\n";
	print "     <TD ALIGN=\"center\" valign=\"middle\" WIDTH=\"150\">\n";
	print "      <div ALIGN=\"center\">\n";
	print "       <b>\n";
	print "        <font face=\"Arial, Helvetica, Geneva, Swiss, SunSans-Regular\" size=\"3\">\n";
	print "         Dia: \n";
	print "        </FONT>\n";
	print "        <font face=\"Courier New, Courier, Monaco\" size=\"3\">\n";
	print "         <SELECT NAME=\"dia_final\">\n";
	for ($i=1; $i<32; $i++)
	{
		$dia=sprintf("%02d", $i);
		print "           <OPTION";
		if ($dia eq $parametro[3])
		{
			print " SELECTED";
		}
		print ">$dia\n";
	}
	print "         </SELECT>\n";
	print "        </FONT>\n";
	print "       </b>\n";
	print "      </div>\n";
	print "     </TD>\n";

	print "     <TD ALIGN=\"left\" valign=\"middle\" WIDTH=\"150\">\n";
	print "      <div ALIGN=\"center\">\n";
	print "       <b>\n";
	print "        <font face=\"Arial, Helvetica, Geneva, Swiss, SunSans-Regular\" size=\"3\">\n";
	print "         Mes: \n";
	print "        </FONT>\n";
	print "        <font face=\"Courier New, Courier, Monaco\" size=\"3\">\n";
	print "         <SELECT NAME=\"mes_final\">\n";
	for ($i=1; $i<13; $i++)
	{
		$mes=sprintf("%02d", $i);
		print "           <OPTION";
		if ($mes eq $parametro[4])
		{
			print " SELECTED";
		}
		print ">$mes\n";
	}
	print "         </SELECT>\n";
	print "        </FONT>\n";
	print "       </b>\n";
	print "      </div>\n";
	print "     </TD>\n";

	print "     <TD ALIGN=\"left\" valign=\"center\" WIDTH=\"200\">\n";
	print "      <div ALIGN=\"center\">\n";
	print "       <b>\n";
	print "        <font face=\"Arial, Helvetica, Geneva, Swiss, SunSans-Regular\" size=\"3\">\n";
	print "         A&ntilde;o: \n";
	print "        </FONT>\n";
	print "        <font face=\"Courier New, Courier, Monaco\" size=\"3\">\n";
	print "         <SELECT NAME=\"anio_final\">\n";
	foreach $anios (@anios)
	{
		print "           <OPTION";
		if ($anios eq $parametro[5])
		{
			print " SELECTED";
		}
		print ">20".$anios."\n";
	}
	print "         </SELECT>\n";
	print "        </FONT>\n";
	print "       </b>\n";
	print "      </div>\n";
	print "     </TD>\n";
	print "    </TR>\n";

	print "    <tr height=\"20\">\n";
	print "     <td align=\"center\" colspan=\"3\" height=\"20\">\n";
	print "      &nbsp;\n";
	print "     </td>\n";
	print "    </tr>\n";

	print "    <TR>\n";
	print "     <TD ALIGN=\"center\" COLSPAN=\"3\">\n";
	print "      <font face=\"Arial, Helvetica, Geneva, Swiss, SunSans-Regular\" size=\"2\">\n";
	print "       <INPUT TYPE=\"submit\" VALUE=\"    Mostrar    \">\n";
	print "      </FONT>\n";
	print "     </TD>\n";
	print "    </TR>\n";
	print "   </TABLE>\n";
	print "  </FORM>\n";
	print "  <BR>\n";
}


END {};

1;
