
import 'package:chat_app/global/enviroment.dart';
import 'package:chat_app/models/mensajes_response.dart';
import 'package:chat_app/models/usuario.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ChatService with ChangeNotifier {

  Usuario usuarioPara;

  Future<List<Mensaje>> getChat( String usuarioID ) async {

    final resp = await http.get('${ Enviroment.apiUrl }/mensajes/$usuarioID',
      headers: {
        'Content-Type': 'application/json',
        'x-token': await AuthService.getToken()
      }
    );

    final mensajesResp = mensajesResponseFromJson(resp.body);

    return mensajesResp.mensaje;

  }

}