METEO VIVO — BUILD 6

NOVITÀ
- Nessun dato dimostrativo: l’app mostra esclusivamente dati reali WeatherKit.
- Nuova schermata di configurazione quando WeatherKit non è autorizzato.
- Nuova icona astratta, moderna e colorata.
- Grafica ulteriormente rifinita con materiali e card traslucide.
- Build tecnica 6, non mostrata nell’app.

CONFIGURAZIONE NECESSARIA
1. Apple Developer > Certificates, Identifiers & Profiles > Identifiers.
2. Apri l’App ID con Bundle ID com.dmb.meteovivo.
3. Attiva WeatherKit e salva.
4. In Xcode > Target MeteoVivo > Signing & Capabilities.
5. Seleziona il tuo Team.
6. Verifica che WeatherKit sia presente; se manca, aggiungilo con + Capability.
7. Xcode > Settings > Accounts > scarica/aggiorna i provisioning profile.
8. Elimina Meteo Vivo dall’iPhone.
9. Product > Clean Build Folder.
10. Installa nuovamente l’app sull’iPhone.

Compatibilità: Xcode 15, iOS 16+.
