#!/usr/bin/env perl6
=NAME portage-equo installer
=DESCRIPTION
Created for use on Sabayon. Meant for installing packages with emerge (portage) that are
not availible with equo (entropy). Installs all dependencies for the package
with equo and then installs the package with portage. Optionally adds the new
portage installed program to C<package.mask>

multi sub MAIN
(
Str:D $query,
Bool:D :$install = False,
Bool:D :$portage-only = False
) {
    my Str:D $result = qqx[equery -C g --depth 1 $query];
    my Str:D @sorted = $result.split("\n\n")>>.trim
            .sort( -> $a is copy, $b is copy {
                #my $b = $^b; my $a = $^a;
                $b = $b.lines[0].subst(/^.*'-'(.*?)':'?$/, {"$0"});
                $a = $a.lines[0].subst(/^.*'-'(.*?)':'?$/, {"$0"});
                $a = 0 if $a eq '9999';
                $b = 0 if $b eq '9999';
                $b cmp $a;
    });
    if !@sorted {
        note $result;
        exit;
    }
    @sorted = @sorted[0].lines;
    my Str:D $name = @sorted.shift;
    $name .= subst: /':'\s*$/, '';
    note "Deps for package: $name";
    my Str:D @deps = @sorted>>.subst( /:s '[' \d+ ']' /, '')>>.trim;
    say @deps.join(' ');
    if $install {
        if $portage-only {
            portage-install $name;
        }
        else {
            install $name, @deps;
        }
    }
        
}
sub install (Str:D $package, Str:D @deps) {
    if %*ENV<USER> ne 'root' {
        note "You are not root. Can't install";
        exit 1;
    }
    my $cmd = run 'equo', 'install', '--ask', |@deps;
    if $cmd.exitcode == 0 {
        if bool-prompt "Do you want to install it using portage now? N/y" {
            portage-install($package);
        }
    }
}
sub seperate-package-version ($_) {
    .match(/  $<package>=(.*?) '-' $<version>=(<[\S]-[-]>+) $/);
    ~$<package> => ~$<version>;
}
my $package-mask = '/etc/entropy/packages/package.mask';
sub bool-prompt (Str:D $line = 'N/y') {
    my $prompt = prompt $line;
    $prompt ~~ /:i << y[es]? >> /;
}
sub portage-install (Str:D $package) {
    my $package-pair = seperate-package-version($package);
    my $cmd = run 'emerge', '--ask', '=' ~ $package;
    if $cmd.exitcode == 0 {
        if bool-prompt "Add entry for $package into $package-mask ?" {
            note "Appending $package-mask with $package-pair.key()";
            $package-mask.IO.spurt: :append, "$package-pair.key()\n";
        }
        note "Resyncing entropy and portage databases";
        my $equo-sync = run |<equo rescue spmsync --ask>;
        say $equo-sync.exitcode;
    }
    
}
multi sub MAIN (Bool:D :$test) {
    require Test <&is &is-deeply &plan>;
    my $pair = seperate-package-version('media-fonts/fira-mono-3.205');
    is-deeply $pair.key, 'media-fonts/fira-mono';
    is-deeply $pair.value, '3.205';
}