import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class ChatScreen extends StatefulWidget {
  final String doctorName;
  final String channelName;
  const ChatScreen({super.key, this.doctorName = 'الطبيب', this.channelName = 'sehatak'});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isInCall = false;
  bool _isVideoCall = false;
  bool _isMuted = false;
  RtcEngine? _engine;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(text: 'مرحباً بك في عيادة ${widget.doctorName}، كيف يمكنني مساعدتك؟', isMe: false, time: '10:00 ص'));
  }

  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: 'a24c7e1ed2f04770ad21281e11915b65'));
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (conn, elapsed) => setState(() => _isInCall = true),
      onUserJoined: (conn, uid, elapsed) => setState(() => _remoteUid = uid),
      onUserOffline: (conn, uid, reason) => setState(() { _remoteUid = null; _isInCall = false; }),
    ));
  }

  Future<void> _startCall({bool video = false}) async {
    await _initAgora();
    setState(() { _isVideoCall = video; _isInCall = true; });
    await _engine?.joinChannel(token: '', channelId: widget.channelName, uid: 0, options: ChannelMediaOptions(clientRoleType: ClientRoleType.clientRoleBroadcaster));
    if (video) { await _engine?.startPreview(); await _engine?.enableVideo(); }
    await _engine?.enableAudio();
  }

  Future<void> _endCall() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    setState(() { _isInCall = false; _isVideoCall = false; _remoteUid = null; });
  }

  void _sendMessage() {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _messages.add(ChatMessage(text: _msgCtrl.text, isMe: true, time: _now())));
    _msgCtrl.clear();
  }

  String _now() {
    final n = DateTime.now();
    return '${n.hour}:${n.minute.toString().padLeft(2, '0')} ${n.hour >= 12 ? "م" : "ص"}';
  }

  @override
  void dispose() {
    _engine?.release();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorName),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () => _startCall()),
          IconButton(icon: const Icon(Icons.videocam), onPressed: () => _startCall(video: true)),
        ],
      ),
      body: _isInCall ? _buildCallUI() : _buildChatUI(),
    );
  }

  Widget _buildCallUI() {
    return Column(children: [
      Expanded(
        child: _isVideoCall && _remoteUid != null
            ? AgoraVideoView(controller: VideoViewController.remote(rtcEngine: _engine!, canvas: VideoCanvas(uid: _remoteUid!), connection: RtcConnection(channelId: widget.channelName)))
            : Container(color: const Color(0xFF1A2540), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.teal, shape: BoxShape.circle), child: const Icon(Icons.person, size: 50, color: Colors.white)),
                const SizedBox(height: 16),
                Text(widget.doctorName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('مكالمة جارية...', style: TextStyle(color: Colors.white70)),
              ]))),
      ),
      Container(color: const Color(0xFF0B1121), padding: const EdgeInsets.symmetric(vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _callBtn(Icons.mic, _isMuted ? Colors.red : Colors.white, () async { setState(() => _isMuted = !_isMuted); await _engine?.muteLocalAudioStream(_isMuted); }),
        _callBtn(Icons.call_end, Colors.red, _endCall, size: 50),
        _callBtn(Icons.videocam, _isVideoCall ? Colors.white : Colors.grey, () {}),
      ])),
    ]);
  }

  Widget _callBtn(IconData icon, Color color, VoidCallback onTap, {double size = 40}) {
    return GestureDetector(onTap: onTap, child: Container(width: size + 10, height: size + 10, decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: size > 45 ? 28 : 22)));
  }

  Widget _buildChatUI() {
    return Column(children: [
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _messages.length, itemBuilder: (_, i) => _buildMessage(_messages[i]))),
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))]), child: SafeArea(child: Row(children: [
        Expanded(child: TextField(controller: _msgCtrl, textAlign: TextAlign.right, decoration: InputDecoration(hintText: 'اكتب رسالة...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[100], contentPadding: const EdgeInsets.symmetric(horizontal: 16)))),
        const SizedBox(width: 6),
        CircleAvatar(backgroundColor: Colors.teal, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage)),
      ]))),
    ]);
  }

  Widget _buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: msg.isMe ? Colors.teal[100] : Colors.grey[200],
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: msg.isMe ? const Radius.circular(16) : const Radius.circular(0), bottomRight: msg.isMe ? const Radius.circular(0) : const Radius.circular(16)),
        ),
        child: Column(crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Text(msg.text, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(msg.time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ]),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  ChatMessage({required this.text, required this.isMe, required this.time});
}
