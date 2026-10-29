import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotifService.init();
  runApp(const ColisApp());
}

// --- DEVISE : DINAR TUNISIEN ---
String fmtDT(double v)=> "${v.toStringAsFixed(3)} DT";

const List<String> villes = ["Tunis","Ariana","Ben Arous","Manouba","Nabeul","Bizerte","Sousse","Monastir","Sfax","Kairouan","Gabès","Médenine"];

// --- NOTIFICATIONS (locales) ---
class NotifService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      _ready = true;
    } catch(e){ debugPrint("Notif init error: $e"); }
  }
  static Future<void> demanderPermission() async {
    try {
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } catch(e){ debugPrint("Notif permission error: $e"); }
  }
  static Future<void> show(String titre, String corps) async {
    if(!_ready) return;
    try {
      const details = NotificationDetails(android: AndroidNotificationDetails(
        'enlevements', "Demandes d'enlèvement",
        channelDescription: "Alertes pour les demandes d'enlèvement dans votre périmètre",
        importance: Importance.max, priority: Priority.high));
      await _plugin.show(DateTime.now().millisecondsSinceEpoch % 100000, titre, corps, details);
    } catch(e){ debugPrint("Notif show error: $e"); }
  }
}

// --- FAUSSE BASE DE DONNÉES POUR TEST ---
enum ColisStatus { cree, attente, enCours, livre, retourProvisoire, retourDefinitif }

class Colis {
  String id; String codeBarre; String expediteurId; String? livreurId;
  String nomClient, telephone, adresse, villeEnlevement, designation; double prixArticle, prixLivraison;
  ColisStatus statut; DateTime date;
  Colis({required this.id, required this.codeBarre, required this.expediteurId, this.livreurId, required this.nomClient, required this.telephone, required this.adresse, required this.villeEnlevement, required this.designation, required this.prixArticle, required this.prixLivraison, required this.statut, required this.date});
}

class MockDB {
  static String currentUserId = "exp1";
  static String currentRole = "expediteur";
  static Set<String> perimetre = {"Tunis","Ariana"}; // villes où le livreur veut être alerté
  static bool notifOn = true;
  static List<Colis> colis = [
    Colis(id: "1", codeBarre: "WS-77382-891", expediteurId: "exp1", livreurId: "liv1", nomClient: "Karim Ben Salah", telephone: "+21620123456", adresse: "Menzah 6, Tunis", villeEnlevement: "Ariana", designation: "Chaussures Nike 42", prixArticle: 185, prixLivraison: 7, statut: ColisStatus.livre, date: DateTime.now()),
    Colis(id: "2", codeBarre: "WS-77383-892", expediteurId: "exp1", nomClient: "Sara Trabelsi", telephone: "+21622345678", adresse: "Route Tunis km 3, Sfax", villeEnlevement: "Tunis", designation: "Robe", prixArticle: 95, prixLivraison: 8, statut: ColisStatus.attente, date: DateTime.now()),
    Colis(id: "3", codeBarre: "WS-77384-893", expediteurId: "exp1", livreurId: "liv1", nomClient: "Amine Dridi", telephone: "+21650456789", adresse: "Khezama, Sousse", villeEnlevement: "Ariana", designation: "Montre", prixArticle: 220, prixLivraison: 7, statut: ColisStatus.retourProvisoire, date: DateTime.now()),
    Colis(id: "4", codeBarre: "WS-77370-880", expediteurId: "exp1", livreurId: "liv1", nomClient: "Yacine Mejri", telephone: "+21698567890", adresse: "Centre ville, Bizerte", villeEnlevement: "Tunis", designation: "Sac", prixArticle: 65, prixLivraison: 6, statut: ColisStatus.livre, date: DateTime.now().subtract(const Duration(days: 5))),
    Colis(id: "5", codeBarre: "WS-77350-870", expediteurId: "exp1", livreurId: "liv1", nomClient: "Nadia Khelifi", telephone: "+21655678901", adresse: "Hammamet, Nabeul", villeEnlevement: "Ariana", designation: "Parfum", prixArticle: 120, prixLivraison: 7, statut: ColisStatus.livre, date: DateTime.now().subtract(const Duration(days: 20))),
  ];
}

class ColisApp extends StatelessWidget {
  const ColisApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wassalni',
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const WelcomeScreen(),
    );
  }
}

// --- WELCOME & REGISTER ---
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.local_shipping, size: 80, color: Colors.indigo),
      const Text("WASSALNI", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const Text("Expéditeur <-> Livreur", style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 40),
      ElevatedButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const RegisterScreen())), child: const Text("S'INSCRIRE - KYC Obligatoire")),
      TextButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const LoginScreen())), child: const Text("J'ai déjà un compte - Se connecter")),
    ]))));
  }
}

class RegisterScreen extends StatefulWidget { const RegisterScreen({super.key}); @override State<RegisterScreen> createState()=> _RegisterScreenState();}
class _RegisterScreenState extends State<RegisterScreen> {
  int step=0; bool cgu=false; String role="expediteur";
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Inscription - Étape ${step+1}/3")), body: Stepper(currentStep: step, onStepContinue: (){
      if(step<2) setState(()=> step++); else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demande envoyée ! Vérification sous 24-48h"))); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const PendingScreen()));}
    }, onStepCancel: ()=> setState(()=> step--), controlsBuilder: (c,d){ return Padding(padding: const EdgeInsets.only(top:16), child: ElevatedButton(onPressed: (step==2 && !cgu)? null: d.onStepContinue, child: Text(step==2? "ENVOYER MA DEMANDE":"Continuer")));},
    steps: [
      Step(title: const Text("Infos Personnelles"), content: Column(children: [
        DropdownButtonFormField(value: role, items: const [DropdownMenuItem(value:"expediteur", child: Text("Je suis Expéditeur")), DropdownMenuItem(value:"livreur", child: Text("Je suis Livreur"))], onChanged:(v)=>setState(()=>role=v!), decoration: const InputDecoration(labelText: "Rôle")),
        const TextField(decoration: InputDecoration(labelText: "Nom *")), const TextField(decoration: InputDecoration(labelText: "Prénom *")),
        const TextField(decoration: InputDecoration(labelText: "Email *", hintText: "code OTP envoyé")), const TextField(decoration: InputDecoration(labelText: "Téléphone *")),
      ])),
      Step(title: const Text("Vérification Identité"), content: Column(children: [
        _uploadTile("Photo RECTO CIN / Passeport *"), _uploadTile("Photo VERSO CIN / Passeport *"), _uploadTile("Facture Eau/Électricité < 3 mois *"),
        const SizedBox(height:8), Container(color: Colors.orange.shade50, padding: const EdgeInsets.all(8), child: const Text("Filigrane auto 'WASSALNI' ajouté pour sécurité", style: TextStyle(fontSize: 12)))
      ])),
      Step(title: const Text("Validation Légale"), content: Column(children: [
        CheckboxListTile(value: cgu, onChanged:(v)=>setState(()=>cgu=v!), title: const Text("Je certifie avoir lu et accepté les CGU et la Politique de Confidentialité *"), subtitle: const Text("Voir CGU | Voir Confidentialité", style: TextStyle(color: Colors.indigo))),
      ])),
    ]));
  }
  Widget _uploadTile(String t)=> Card(child: ListTile(leading: const Icon(Icons.camera_alt, color: Colors.indigo), title: Text(t), trailing: const Icon(Icons.check_circle, color: Colors.green), onTap: (){}));
}
class PendingScreen extends StatelessWidget { const PendingScreen({super.key}); @override Widget build(BuildContext context)=> Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.hourglass_top, size: 80, color: Colors.orange), const Text("Compte en cours de vérification", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text("Admin vérifie vos documents sous 24-48h", textAlign: TextAlign.center), const SizedBox(height:20), ElevatedButton(onPressed: ()=> Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const LoginScreen())), child: const Text("Aller au Login (DEMO)"))]))));}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Connexion DEMO")), body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const TextField(decoration: InputDecoration(labelText: "Email")), const TextField(decoration: InputDecoration(labelText: "Mot de passe"), obscureText: true), const SizedBox(height:20),
      ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity,50)), onPressed: (){ MockDB.currentRole="expediteur"; Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const ExpediteurHome()));}, child: const Text("Se connecter comme EXPÉDITEUR")),
      const SizedBox(height:12),
      ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity,50), backgroundColor: Colors.teal), onPressed: (){ MockDB.currentRole="livreur"; Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const LivreurHome()));}, child: const Text("Se connecter comme LIVREUR", style: TextStyle(color: Colors.white))),
    ])));
  }
}

// --- ESPACE EXPEDITEUR ---
class ExpediteurHome extends StatefulWidget { const ExpediteurHome({super.key}); @override State<ExpediteurHome> createState()=> _ExpHomeState();}
class _ExpHomeState extends State<ExpediteurHome>{
  int idx=0;
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: const Text("Expéditeur Dashboard"), actions: [IconButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const CreateColisScreen())), icon: const Icon(Icons.add))]),
      body: [const DashboardExp(), const ListeColisExp(), const QrClotureScreen()][idx],
      bottomNavigationBar: NavigationBar(selectedIndex: idx, onDestinationSelected:(i)=>setState(()=>idx=i), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard), label: "Dashboard"), NavigationDestination(icon: Icon(Icons.list_alt), label: "Mes Colis"), NavigationDestination(icon: Icon(Icons.qr_code), label: "Clôture")]),
      floatingActionButton: FloatingActionButton.extended(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const CreateColisScreen())).then((_)=>setState((){})), label: const Text("Nouveau Bordereau"), icon: const Icon(Icons.add)),
    );
  }
}
class DashboardExp extends StatefulWidget{ const DashboardExp({super.key}); @override State<DashboardExp> createState()=> _DashboardExpState();}
class _DashboardExpState extends State<DashboardExp>{
  DateTimeRange? plage; // null = toutes les dates

  DateTime _jour(DateTime d)=> DateTime(d.year, d.month, d.day);
  String _fmt(DateTime d)=> "${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}";
  String get _plageTexte => plage==null ? "Toutes les dates" : "Du ${_fmt(plage!.start)} au ${_fmt(plage!.end)}";

  void _preset(int jours){
    final fin=_jour(DateTime.now());
    setState(()=> plage=DateTimeRange(start: fin.subtract(Duration(days: jours-1)), end: fin));
  }

  Future<void> _choisir() async {
    final now=DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year+1, 12, 31),
      initialDateRange: plage,
      locale: const Locale('fr'),
      helpText: "Choisir une plage de dates",
      saveText: "OK",
    );
    if(r!=null) setState(()=> plage=r);
  }

  bool _dansPlage(Colis c){
    if(plage==null) return true;
    final d=_jour(c.date);
    return !d.isBefore(plage!.start) && !d.isAfter(plage!.end);
  }

  @override Widget build(BuildContext context){
    var mine = MockDB.colis.where((c)=>c.expediteurId=="exp1").toList();
    var all = mine.where(_dansPlage).toList();
    var livresList = all.where((c)=>c.statut==ColisStatus.livre).toList();
    int livres = livresList.length;
    int prov = all.where((c)=>c.statut==ColisStatus.retourProvisoire).length;
    int def = all.where((c)=>c.statut==ColisStatus.retourDefinitif).length;
    double encaisse = livresList.fold<double>(0, (s,c)=>s+c.prixArticle);
    double aCollecter = mine.where((c)=>c.statut==ColisStatus.livre).fold<double>(0, (s,c)=>s+c.prixArticle);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(onTap: _choisir, child: Row(children: [
          const Icon(Icons.date_range), const SizedBox(width:8),
          Expanded(child: Text(_plageTexte, style: const TextStyle(fontWeight: FontWeight.bold))),
          if(plage!=null) IconButton(onPressed: ()=> setState(()=> plage=null), icon: const Icon(Icons.close), tooltip: "Effacer"),
          const Icon(Icons.arrow_drop_down),
        ])),
        const SizedBox(height:8),
        Wrap(spacing: 8, children: [
          ActionChip(label: const Text("Aujourd'hui"), onPressed: ()=> _preset(1)),
          ActionChip(label: const Text("7 jours"), onPressed: ()=> _preset(7)),
          ActionChip(label: const Text("30 jours"), onPressed: ()=> _preset(30)),
          ActionChip(label: const Text("Tout"), onPressed: ()=> setState(()=> plage=null)),
        ]),
      ]))),
      const SizedBox(height:12),
      Row(children: [Expanded(child: _card("LIVRÉS", "$livres", Colors.green)), const SizedBox(width:8), Expanded(child: _card("PROVISOIRE", "$prov", Colors.orange)), const SizedBox(width:8), Expanded(child: _card("DÉFINITIF", "$def", Colors.red))]),
      const SizedBox(height:12),
      Card(color: Colors.green.shade700, child: SizedBox(width: double.infinity, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        const Text("MONTANT ENCAISSÉ", style: TextStyle(color: Colors.white70)),
        Text(fmtDT(encaisse), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        Text("$livres colis livrés - $_plageTexte", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ])))),
      const SizedBox(height:8),
      Card(color: Colors.indigo, child: SizedBox(width: double.infinity, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [const Text("ARGENT À COLLECTER", style: TextStyle(color: Colors.white70)), Text(fmtDT(aCollecter), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), const Text("Chez le livreur - À clôturer par QR Scan", style: TextStyle(color: Colors.white70, fontSize: 12))])))),
      const SizedBox(height:12),
      const Text("Activité Récente", style: TextStyle(fontWeight: FontWeight.bold)),
      if(all.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text("Aucun colis sur cette période"))),
      ...all.map((c)=> ListTile(leading: Icon(Icons.inventory_2, color: _color(c.statut)), title: Text(c.nomClient), subtitle: Text("${c.codeBarre} - ${_label(c.statut)}\n${_fmt(c.date)}"), isThreeLine: true, trailing: Text(fmtDT(c.prixArticle)))),
    ]);
  }
  Widget _card(String t,String v,Color c)=> Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text(t, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold)), Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))])));
}
class ListeColisExp extends StatefulWidget{ const ListeColisExp({super.key}); @override State<ListeColisExp> createState()=> _ListeColisExpState();}
class _ListeColisExpState extends State<ListeColisExp>{
  @override Widget build(BuildContext context){
    var list = MockDB.colis.where((c)=>c.expediteurId=="exp1").toList();
    return ListView.builder(itemCount: list.length, itemBuilder: (c,i){
      var col=list[i];
      return Card(margin: const EdgeInsets.symmetric(horizontal:12, vertical:6), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(col.codeBarre, style: const TextStyle(fontWeight: FontWeight.bold)), Chip(label: Text(_label(col.statut), style: const TextStyle(fontSize:10)), backgroundColor: _color(col.statut).withOpacity(0.2))]),
        Text("${col.nomClient} - ${col.adresse}"), Text("${col.designation} - ${fmtDT(col.prixArticle)} + Livraison ${fmtDT(col.prixLivraison)}", style: const TextStyle(color: Colors.grey)),
        const SizedBox(height:8),
        BarcodeWidget(barcode: Barcode.code128(), data: col.codeBarre, width: double.infinity, height: 50, drawText: true),
        if(col.statut==ColisStatus.attente) Row(children: [const Icon(Icons.person_add, size:16, color: Colors.teal), const Text(" Livreur veut enlever - ", style: TextStyle(fontSize:12)), TextButton(onPressed: (){ setState((){ col.statut=ColisStatus.enCours; col.livreurId="liv1"; }); ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text("Accepté ! Mise en contact")));}, child: const Text("ACCEPTER")), TextButton(onPressed: (){ ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text("Demande refusée")));}, child: const Text("REFUSER"))])
      ])));
    });
  }
}
class QrClotureScreen extends StatelessWidget{ const QrClotureScreen({super.key});
  @override Widget build(BuildContext context){
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("QR DE CLÔTURE JOURNALIÈRE", style: TextStyle(fontWeight: FontWeight.bold)),
      const Text("Le livreur doit scanner ce QR pour te rendre l'argent + retours provisoires", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      const SizedBox(height:16),
      QrImageView(data: "EXP1-CLOTURE-${DateTime.now().day}", version: QrVersions.auto, size: 200),
      const SizedBox(height:12), const Text("EXP1 - Ahmed Boutique", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height:20), const Card(child: Padding(padding: EdgeInsets.all(12), child: Text("Tant que ce QR n'est pas scanné, la journée n'est PAS clôturée et l'argent reste 'À collecter'"))),
    ])));
  }
}
class CreateColisScreen extends StatefulWidget{ const CreateColisScreen({super.key}); @override State<CreateColisScreen> createState()=> _CreateState();}
class _CreateState extends State<CreateColisScreen>{
  final nom=TextEditingController(), tel=TextEditingController(), adresse=TextEditingController(), desig=TextEditingController(), prix=TextEditingController(text:"85"), prixLiv=TextEditingController(text:"7");
  String ville = "Tunis";
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: const Text("Nouveau Bordereau")), body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: nom, decoration: const InputDecoration(labelText: "Nom Client *", border: OutlineInputBorder())), const SizedBox(height:12),
      TextField(controller: tel, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Téléphone Client *", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())), const SizedBox(height:12),
      TextField(controller: adresse, decoration: const InputDecoration(labelText: "Adresse de livraison + Ville *", border: OutlineInputBorder())), const SizedBox(height:12),
      DropdownButtonFormField<String>(value: ville, decoration: const InputDecoration(labelText: "Ville d'enlèvement (où récupérer le colis)", border: OutlineInputBorder()), items: villes.map((v)=> DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v)=> setState(()=> ville = v ?? ville)), const SizedBox(height:12),
      TextField(controller: desig, decoration: const InputDecoration(labelText: "Désignation Produit *", border: OutlineInputBorder())), const SizedBox(height:12),
      Row(children: [Expanded(child: TextField(controller: prix, decoration: const InputDecoration(labelText: "Prix Article (COD) DT", border: OutlineInputBorder()), keyboardType: TextInputType.number)), const SizedBox(width:12), Expanded(child: TextField(controller: prixLiv, decoration: const InputDecoration(labelText: "Prix Livraison DT", border: OutlineInputBorder()), keyboardType: TextInputType.number))]),
      const SizedBox(height:20),
      ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity,50), backgroundColor: Colors.indigo, foregroundColor: Colors.white), onPressed: (){
        var code="WS-${Random().nextInt(90000)+10000}-${Random().nextInt(900)+100}";
        final nouveau = Colis(id: code, codeBarre: code, expediteurId: "exp1", nomClient: nom.text.isEmpty?"Client":nom.text, telephone: tel.text.trim(), adresse: adresse.text.isEmpty?"Tunis":adresse.text, villeEnlevement: ville, designation: desig.text.isEmpty?"Produit":desig.text, prixArticle: double.tryParse(prix.text.replaceAll(',', '.'))??0, prixLivraison: double.tryParse(prixLiv.text.replaceAll(',', '.'))??0, statut: ColisStatus.attente, date: DateTime.now());
        MockDB.colis.add(nouveau);
        // Alerte livreur si l'enlèvement est dans son périmètre
        if(MockDB.notifOn && MockDB.perimetre.contains(ville)){
          NotifService.show("Nouvelle demande d'enlèvement", "$ville - ${nouveau.designation} - Gain ${fmtDT(nouveau.prixLivraison)}");
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bordereau $code créé !")));
        Navigator.pop(context);
      }, child: const Text("GÉNÉRER BORDEREAU + CODE-BARRES")),
    ]));
  }
}

// --- ESPACE LIVREUR ---
class LivreurHome extends StatefulWidget{ const LivreurHome({super.key}); @override State<LivreurHome> createState()=> _LivHomeState();}
class _LivHomeState extends State<LivreurHome>{ int idx=0;
  @override void initState(){ super.initState(); NotifService.demanderPermission(); }

  void _perimetre(){
    showDialog(context: context, builder: (_)=> StatefulBuilder(builder: (ctx,setS)=> AlertDialog(
      title: const Text("Mon périmètre"),
      content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text("Notifications d'enlèvement"), value: MockDB.notifOn, onChanged: (v)=> setS(()=> MockDB.notifOn=v)),
        const Divider(),
        const Text("Me prévenir pour les enlèvements à :", style: TextStyle(fontWeight: FontWeight.bold)),
        ...villes.map((v)=> CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(v), value: MockDB.perimetre.contains(v), onChanged: (on)=> setS((){ if(on==true){ MockDB.perimetre.add(v); } else { MockDB.perimetre.remove(v); } }))),
      ])),
      actions: [
        TextButton(onPressed: ()=> NotifService.show("Wassalni", "Test : les notifications fonctionnent"), child: const Text("TESTER")),
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text("OK")),
      ],
    ))).then((_)=> setState((){}));
  }

  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: const Text("Espace Livreur"), backgroundColor: Colors.teal, foregroundColor: Colors.white, actions: [IconButton(onPressed: _perimetre, icon: const Icon(Icons.location_on), tooltip: "Mon périmètre")]),
      body: [const DemandesList(), const MesColisLivreur(), const ClotureLivreurScreen()][idx],
      bottomNavigationBar: NavigationBar(selectedIndex: idx, onDestinationSelected:(i)=>setState(()=>idx=i), destinations: const [NavigationDestination(icon: Icon(Icons.search), label: "Demandes"), NavigationDestination(icon: Icon(Icons.delivery_dining), label: "Mes Colis"), NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: "Clôture")]),
    );
  }
}
class DemandesList extends StatelessWidget{ const DemandesList({super.key});
  @override Widget build(BuildContext context){
    var demandes = MockDB.colis.where((c)=>c.statut==ColisStatus.attente).toList();
    return ListView.builder(itemCount: demandes.length, itemBuilder: (c,i){
      var col=demandes[i];
      final dansPerimetre = MockDB.perimetre.contains(col.villeEnlevement);
      return Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text("Enlèvement : ${col.villeEnlevement}", style: const TextStyle(fontWeight: FontWeight.bold))), Chip(label: Text(dansPerimetre ? "Dans mon périmètre" : "Hors périmètre", style: const TextStyle(fontSize: 11)), backgroundColor: dansPerimetre ? Colors.green.shade100 : Colors.grey.shade300)]),
        Text("Destination : ${col.adresse} | ${col.designation}"), Text("Gain : ${fmtDT(col.prixLivraison)} / colis", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        const SizedBox(height:8), ElevatedButton(onPressed: (){ ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text("Demande envoyée à l'expéditeur - En attente d'acceptation")));}, child: const Text("POSTULER POUR L'ENLÈVEMENT"))
      ])));
    });
  }
}
class MesColisLivreur extends StatefulWidget{ const MesColisLivreur({super.key}); @override State<MesColisLivreur> createState()=> _MesState();}
class _MesState extends State<MesColisLivreur>{
  @override Widget build(BuildContext context){
    var list = MockDB.colis.where((c)=>c.livreurId=="liv1" && c.statut!=ColisStatus.attente).toList();
    return ListView.builder(itemCount: list.length, itemBuilder: (c,i){
      var col=list[i];
      return Card(margin: const EdgeInsets.all(8), child: ListTile(
        onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> ColisDetailScreen(col: col))).then((_)=> setState((){})),
        title: Text(col.nomClient), subtitle: Text("${col.adresse} - ${fmtDT(col.prixArticle)}"),
        trailing: PopupMenuButton(onSelected: (v){ setState((){ if(v=="livre") col.statut=ColisStatus.livre; if(v=="prov") col.statut=ColisStatus.retourProvisoire; if(v=="def") col.statut=ColisStatus.retourDefinitif; });}, itemBuilder: (_)=> const [PopupMenuItem(value:"livre", child: Text("✅ Livré - Argent Collecté")), PopupMenuItem(value:"prov", child: Text("↩️ Retour Provisoire - Demain")), PopupMenuItem(value:"def", child: Text("❌ Retour Définitif - Refus"))]),
        leading: Icon(Icons.circle, color: _color(col.statut))));
    });
  }
}

// --- DÉTAIL D'UN COLIS (livreur) : infos + appel + SMS ---
class ColisDetailScreen extends StatelessWidget{
  final Colis col;
  const ColisDetailScreen({super.key, required this.col});

  Future<void> _ouvrir(BuildContext context, Uri uri) async {
    bool ok = false;
    try { ok = await launchUrl(uri); } catch(_){ ok = false; }
    if(!ok && context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir l'application du téléphone")));
    }
  }

  Widget _ligne(IconData icone, String titre, String valeur)=> ListTile(leading: Icon(icone, color: Colors.teal), title: Text(titre, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(valeur, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)));

  @override Widget build(BuildContext context){
    final tel = col.telephone.replaceAll(' ', '');
    final sms = "Bonjour ${col.nomClient}, je suis votre livreur Wassalni. Je vous livre votre colis (${col.designation}). Montant : ${fmtDT(col.prixArticle)}. Merci de me confirmer votre disponibilité.";
    return Scaffold(
      appBar: AppBar(title: Text(col.codeBarre), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Card(child: Column(children: [
          _ligne(Icons.person, "Nom du client", col.nomClient),
          _ligne(Icons.phone, "Téléphone", col.telephone.isEmpty ? "Non renseigné" : col.telephone),
          _ligne(Icons.location_on, "Adresse de livraison", col.adresse),
          _ligne(Icons.inventory_2, "Désignation", col.designation),
          _ligne(Icons.payments, "Prix de l'article", fmtDT(col.prixArticle)),
          _ligne(Icons.local_shipping, "Frais de livraison", fmtDT(col.prixLivraison)),
          _ligne(Icons.flag, "Statut", _label(col.statut)),
        ])),
        const SizedBox(height:16),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0,52), backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: tel.isEmpty ? null : ()=> _ouvrir(context, Uri(scheme: 'tel', path: tel)),
            icon: const Icon(Icons.call), label: const Text("APPELER"))),
          const SizedBox(width:12),
          Expanded(child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0,52), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: tel.isEmpty ? null : ()=> _ouvrir(context, Uri.parse("sms:$tel?body=${Uri.encodeComponent(sms)}")),
            icon: const Icon(Icons.sms), label: const Text("SMS"))),
        ]),
      ]),
    );
  }
}

class ClotureLivreurScreen extends StatelessWidget{ const ClotureLivreurScreen({super.key});
  @override Widget build(BuildContext context){
    var livres = MockDB.colis.where((c)=>c.livreurId=="liv1" && c.statut==ColisStatus.livre).toList();
    double totalCollecte = livres.fold<double>(0, (s,c)=>s+c.prixArticle);
    double gain = livres.fold<double>(0, (s,c)=>s+c.prixLivraison);
    double aRendre = totalCollecte - gain;
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        const Text("RÉCAPITULATIF JOURNÉE", style: TextStyle(fontWeight: FontWeight.bold)), const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Colis Livrés: ${livres.length}"), Text("${fmtDT(totalCollecte)} Collectés")]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Mon Gain:"), Text(fmtDT(gain), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
        const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("À RENDRE à l'expéditeur:", style: TextStyle(fontWeight: FontWeight.bold)), Text(fmtDT(aRendre), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo))]),
      ]))),
      const SizedBox(height:20),
      ElevatedButton.icon(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity,50), backgroundColor: Colors.teal, foregroundColor: Colors.white), onPressed: (){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR Expéditeur scanné ✅ Journée Clôturée ! Gain transféré")));}, icon: const Icon(Icons.qr_code_scanner), label: const Text("SCANNER QR EXPÉDITEUR POUR CLÔTURER")),
      const SizedBox(height:8), const Text("Ramène l'argent + les colis provisoires et scanne le QR de l'expéditeur", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))
    ]));
  }
}

String _label(ColisStatus s){ switch(s){ case ColisStatus.cree: return "CRÉÉ"; case ColisStatus.attente: return "EN ATTENTE"; case ColisStatus.enCours: return "EN COURS"; case ColisStatus.livre: return "LIVRÉ"; case ColisStatus.retourProvisoire: return "RETOUR PROVISOIRE"; case ColisStatus.retourDefinitif: return "RETOUR DÉFINITIF";}}
Color _color(ColisStatus s){ switch(s){ case ColisStatus.livre: return Colors.green; case ColisStatus.retourProvisoire: return Colors.orange; case ColisStatus.retourDefinitif: return Colors.red; case ColisStatus.attente: return Colors.blue; case ColisStatus.enCours: return Colors.teal; default: return Colors.grey;}}
