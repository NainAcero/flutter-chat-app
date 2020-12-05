import 'dart:io';

import 'package:chat_app/models/mensajes_response.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/services/socket_service.dart';
import 'package:chat_app/widgets/chat_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {

  ChatService chatService;
  SocketService socketService;
  AuthService authService;

  final _textController = new TextEditingController();
  final _focusNone = new FocusNode();

  List<ChatMessage> _message = [

  ];

  bool _estaEscribiendo = false;

  @override
  void initState() {
    super.initState();

    this.chatService    = Provider.of<ChatService>(context, listen: false);;
    this.socketService  = Provider.of<SocketService>(context, listen: false);;
    this.authService    = Provider.of<AuthService>(context, listen: false);;

    this.socketService.socket.on('mensaje-personal', _escucharMensaje);

    _cargarHistorial( this.chatService.usuarioPara.uid );
  }

  void _cargarHistorial(String usuarioId) async{

    List<Mensaje> chat = await this.chatService.getChat(usuarioId);

    final history = chat.map((m) => new ChatMessage(
      texto: m.mensaje,
      uid: m.de,
      animationController: AnimationController(vsync: this, duration: Duration( milliseconds: 0 ))..forward(),
    ));

    setState(() {
      _message.insertAll(0, history);
    });
  }

  void _escucharMensaje( dynamic payload ){
    print(payload['mensaje']);

    ChatMessage message = new ChatMessage(
      texto: payload['mensaje'], 
      uid: payload['de'],
      animationController: AnimationController(vsync: this, duration: Duration( milliseconds: 400 )),
    );

    setState(() {
      _message.insert(0, message);
    });

    message.animationController.forward();
  }

  @override
  Widget build(BuildContext context) {

    final usuarioPara = chatService.usuarioPara;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          children: <Widget>[
            CircleAvatar(
              child: Text(usuarioPara.nombre.substring(0,2), style: TextStyle(fontSize: 12),),
              backgroundColor: Colors.blue[100],
              maxRadius: 14,
            ),
            SizedBox( height: 3 ),
            Text(usuarioPara.nombre, style: TextStyle( color:  Colors.black87, fontSize: 14),)
          ],
        ),
        centerTitle: true,
        elevation: 1,
      ),

      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: _message.length,
                itemBuilder: (_, i) => _message[i],
                reverse: true,
              )
            ),

            Divider( height: 1 ),

            Container(
              color: Colors.white,
              child: _inputChat(),
            )
          ],
        ),
      ),
   );
  }

  Widget _inputChat(){
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric( horizontal: 8.0 ),
        child: Row(
          children: <Widget>[

            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmit,
                onChanged: ( String texto ) {
                  setState(() {
                    if(texto.trim().length > 0){
                      _estaEscribiendo = true;
                    }else{
                      _estaEscribiendo = false;
                    }
                  });
                },
                decoration: InputDecoration.collapsed(
                  hintText: 'Enviar Mensaje'
                ),
                focusNode: _focusNone,
              )
            ),

            Container(
              margin: EdgeInsets.symmetric( horizontal: 4.0 ),
              child: Platform.isIOS
              ? CupertinoButton(
                child: Text('Enviar'), 
                onPressed:  _estaEscribiendo 
                  ? () => _handleSubmit( _textController.text )
                  : null,
              ) : Container(
                margin: EdgeInsets.symmetric( horizontal: 4.0 ),
                child: IconTheme(
                  data: IconThemeData(color: Colors.blue[400] ),
                  child: IconButton(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    icon: Icon( Icons.send, ), 
                    onPressed: _estaEscribiendo 
                      ? () => _handleSubmit( _textController.text )
                      : null,
                  ),
                ),
              )
            )
          ],
        ),
      ),
    );
  }

  _handleSubmit( String texto ) {

    if( texto.trim().length == 0 ) return;

    // print(texto);
    _textController.clear();
    _focusNone.requestFocus();

    final newMessage = new ChatMessage(
      texto: texto, 
      uid: authService.usuario.uid,
      animationController: AnimationController(vsync: this, duration: Duration( milliseconds: 400 )),
    );
    _message.insert(0, newMessage);
    newMessage.animationController.forward();

    setState(() { // para que haga los cambios
      _estaEscribiendo = false;
    });

    this.socketService.emit('mensaje-personal', {
      'de': this.authService.usuario.uid,
      'para': this.chatService.usuarioPara.uid,
      'mensaje': texto
    });

  }

  @override
  void dispose() {
    
    for( ChatMessage message in _message ){
      message.animationController.dispose();
    }
    
    this.socketService.socket.off('mensaje-personal');
    super.dispose();
  }
}