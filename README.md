## Arbejdsrutine
- Pull fra main
- Checkout til din egen lokale branch, sådan at hvis du fucker noget op, så pusher du ikke til main og ødelægger noget
- Når din lort fungerer, checkout til main og commit/ push til main

## Eksempel på at lave egen branch
```sh
git checkout -b branch
```
opretter lokal branch der hedder `branch` og skifter til den
```sh
git checkout main
```
skifter tilbage til `main`. Uden `-b` flaget skifter man bare mellem eksisterende branches. `-b` flaget laver ny branch.
```sh
git branch
```
giver liste af tilgængelige branches.
```sh
git add -A
```
Tilføjer alle oprettede filer, skal bruges ved .xlsx filer
```sh
git push -u origin branch
```
pusher indhold fra branch til main.
Alternaivt: Hvis du er i `main` og vil pulle til `main` fra en branch
```sh
git pull origin branch
```
Til slut, som altid (når du står i `main`)
```sh
git commit -m "commit message"
git push
```
