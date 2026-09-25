---
layout: "../../../layouts/blog-layout.astro"
title: "Bezpečnosť a spoľahlivosť: Prečo appka, ktorá funguje, nestačí"
description:
    "Každý z nás už zažil appku, ktorá v tej najhoršej možnej chvíli spadla.
    Formulár vyplnený, palec nad tlačidlom 'Odoslať', a zrazu biela obrazovka.
    Za týmto jedným momentom frustrácie sa skrýva celá disciplína, ktorá
    rozhoduje o tom, či používateľ aplikácii dôveruje, alebo ju po týždni
    vymaže. V tomto článku sa pozrieme na to, prečo je testovanie také dôležité,
    aké typy testovania poznáme, prečo appky neustále potrebujú aktualizácie a
    ako vlastne predchádzame chybám skôr, než sa k nim dostane používateľ."
image: {
    src: "/images/banners/app-security-1.png",
    alt: ""
}
date: 2026-06-11
author: "Jakub Guštafik"
---

Keď väčšina ľudí počuje slovo "appka", predstaví si dizajn, ikonky a možno
nejaké tie funkcie. Čo si nikto nepredstaví, je tá nudná, neviditeľná polovica
vývoja - tá, ktorá sa stará o to, aby tie pekné ikonky nedekorovali
stenu chybových hlášok. A presne o tom je bezpečnosť a spoľahlivosť.

## "A nestačí, že to proste funguje?"

To, že appka funguje dnes, je len začiatok. Spoľahlivosť je schopnosť
aplikácie robiť to, čo má, konzistentne - aj v situáciách, ktoré nikto
vopred nevymyslel, a aj o pol roka, keď sa okolo nej všetko zmení.

A je v tom aj jedna menej viditeľná vec. Nestačí, že to funguje dnes, keď
developer, ktorý appku napísal, na ďalší deň nepríde do práce a nikto iný
sa už v tom kóde nevyzná. Nestačí, že to funguje, keď treba pridať jednu
malú funkciu a pritom sa rozsype niečo úplne iné. Dobrá aplikácia je
postavená tak, aby sa o ňu vedel postarať aj človek, ktorý ju nepísal -
a aby ju ten, čo ju písal, vôbec chcel ešte raz otvoriť.

A presne k tomu slúžia veci ako testovanie, prehľadný kód a poriadok
vo vývoji.

## Prečo vôbec testujeme

Testovanie je proces, pri ktorom zámerne hľadáme chyby skôr, ako ich nájde
používateľ. Znie to triviálne, ale je v tom dôležitý posun v myslení -
nehráme sa na to, že náš kód je dokonalý, ale aktívne sa ho snažíme zlomiť.

Robíme to preto, lebo cena chyby rastie s tým, ako neskoro ju nájdeme.
Bug odchytený pri písaní kódu stojí pár minút. Ten istý bug, ktorý sa
dostane k tisíckam používateľov, môže stáť reputáciu značky a hromadu
negatívnych recenzií. (a ako vieme z iných príbehov, recenzie vedia značku
spraviť alebo zničiť)

Inými slovami - nedostatočné testovanie vedie k tomu, že aplikáciu
testujú samotní používatelia. A tí za to neplatia, takže nie sú vôbec nadšení.

## Aké typy testovania poznáme

Testovanie nie je jedna vec, je to skôr taký balík rôznych pohľadov na ten
istý problém. Tie najčastejšie tri sú:

- Funkčné testovanie overuje, či appka robí to, čo má. Používateľ klikne
  na tlačidlo "Prihlásiť" a očakáva, že ho to prihlási - nie že ho to odhlási
  alebo vymaže účet. Sem patrí aj automatizované testovanie, kde namiesto človeka klikanie
  simuluje kód.
- Používateľské testovanie rieši niečo úplne iné: či tomu reálny človek
  rozumie. Appka môže byť technicky bezchybná a aj tak úplne nepoužiteľná,
  keď používateľ nevie nájsť tlačidlo, ktoré hľadá.
- Bezpečnostné testovanie sa pýta tú nepríjemnú otázku: čo sa stane, keď
  sa appku niekto pokúsi zneužiť? Testujú sa veci ako neoprávnený prístup k
  dátam, slabé heslá alebo zraniteľnosti, cez ktoré by sa útočník dostal tam,
  kam nemá.

Každý z týchto pohľadov chytí iný druh problému. Preto sa väčšinou nepoužíva
len jeden - dobrá aplikácia prejde cez všetky tri.

## Prečo appky neustále otravujú s aktualizáciami

Notifikáciu "K dispozícii je nová aktualizácia" väčšina ľudí radšej odklikne
preč. Lenže aktualizácie nie sú len o nových funkciách.

Veľká časť z nich sú tzv. bezpečnostné patche - záplaty dier, ktoré sa
objavili až po vydaní aplikácie. Svet okolo appky sa totiž mení: objavujú sa
nové typy útokov, operačné systémy sa menia a knižnice, na ktorých appka stojí,
dostávajú vlastné úpravy. V dôsledku toho appka, ktorá bola bezpečná pred
rokom, dnes bezpečná byť nemusí.

Takže keď sa appka dlho neaktualizuje, nezostáva "rovnako dobrá" - pomaly sa
stáva zraniteľnejšou, pretože zvyšok sveta sa pohol ďalej a ona nie.

## Ochrana osobných údajov

Pár základných princípov, ktoré by mala dodržiavať každá aplikácia:

1. Zbierať len to, čo je naozaj potrebné. (appka na poznámky nepotrebuje
   prístup ku kontaktom)
2. Citlivé dáta ako heslá nikdy neukladať v čitateľnej podobe - na to slúži
   hashovanie a šifrovanie, vďaka ktorým sú dáta nečitateľné aj v
   prípade, že ich niekto ukradne.
3. Byť transparentný v tom, čo sa s dátami deje.

Nedodržanie týchto princípov spôsobuje únik dát, a únik dát zasa vedie k
strate dôvery, z ktorej sa značka spamätáva fakt ťažko.

## Ako predchádzame chybám skôr, než sa stanú

Najlepší bug je ten, ktorý sa nikdy nedostane k používateľovi. Okrem už
spomínaného testovania sa na to používa niekoľko vrstiev:

- Ošetrenie chýb (error handling) - appka počíta s tým, že niečo pôjde
  zle, a namiesto pádu zobrazí predpripravenú hlášku.
- Code review - predtým, než sa kód dostane do appky, prejde ho ešte aspoň
  jeden ďalší vývojár, aby chytil chyby, ktoré autor mohol prehliadnuť.
- Monitoring - aj po vydaní appka hlási, keď sa niečo deje, takže sa chyba
  zachytí skôr, ako sa o nej tím dozvie z recenzií.

## Zhrnutie

Bezpečnosť a spoľahlivosť sú práve tá časť vývoja, ktorú používateľ vidí len
vtedy, keď chýba. Nikto nenapíše nadšenú recenziu o tom, že appka nespadla
a dáta mu neunikli. Ale práve táto neviditeľná práca je to, čo rozhoduje o
tom, či sa používateľ vráti.

Takže nabudúce, keď si appka pýta aktualizáciu - možno ju radšej nainštalujme. :)

Vďaka za prečítanie!
