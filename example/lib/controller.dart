import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:midi_controller/midi_command.dart';
import 'package:midi_controller/midi_messager.dart';
import 'package:flutter_virtual_piano/flutter_virtual_piano.dart';

class ControllerPage extends StatelessWidget {
  final MidiDevice device;

  const ControllerPage(this.device, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: MidiControls(device));
  }
}

class MidiControls extends StatefulWidget {
  final MidiDevice device;

  const MidiControls(this.device, {Key? key}) : super(key: key);

  @override
  MidiControlsState createState() {
    return MidiControlsState();
  }
}

class MidiControlsState extends State<MidiControls> {
  final _channel = 0;
  var _pitchValue = 0.0;

  StreamSubscription<MidiPacket>? _rxSubscription;
  final MidiCommand _midiCommand = MidiCommand();

  @override
  void initState() {
    if (kDebugMode) {
      print('init controller');
    }
    _rxSubscription = _midiCommand.onMidiDataReceived?.listen((packet) {
      if (kDebugMode) {
        print('received packet $packet');
      }
      var data = packet.data;
      var timestamp = packet.timestamp;
      var device = packet.device;
      if (kDebugMode) {
        print(
            "data $data @ time $timestamp from device ${device.name}:${device.id}");
      }

      var status = data[0];

      if (status == 0xF8) {
        // Beat
        return;
      }

      if (status == 0xFE) {
        // Active sense;
        return;
      }

      if (data.length >= 2) {
        var rawStatus = status & 0xF0; // without channel
        var channel = (status & 0x0F);
        if (channel == _channel) {
          var d1 = data[1];
          switch (rawStatus) {
            case 0xE0: // Pitch Bend
              setState(() {
                var rawPitch = d1 + (data[2] << 7);
                _pitchValue = (((rawPitch) / 0x3FFF) * 2.0) - 1;
              });
              break;
          }
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    // _setupSubscription?.cancel();
    _rxSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          children: <Widget>[
            Text("Pitch Bend", style: Theme.of(context).textTheme.titleLarge),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height / 5),
              child: Slider(
                  value: _pitchValue,
                  max: 1,
                  min: -1,
                  onChanged: _onPitchChanged,
                  onChangeEnd: (_) {
                    _onPitchChanged(0);
                  }),
            ),
            const Divider(),
            Expanded(
              child: VirtualPiano(
                noteRange: const RangeValues(48, 76),
                onNotePressed: (note, vel) {
                  NoteOnMessage(note: note, velocity: 100).send();
                },
                onNoteReleased: (note) {
                  NoteOffMessage(note: note).send();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onPitchChanged(double newValue) {
    setState(() {
      _pitchValue = newValue;
    });
    PitchBendMessage(channel: _channel, bend: _pitchValue).send();
  }
}

class SlidingSelector extends StatelessWidget {
  final String label;
  final int minValue;
  final int maxValue;
  final int value;
  final Function(int) callback;

  const SlidingSelector(
      this.label, this.value, this.minValue, this.maxValue, this.callback,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(label),
        Slider(
          value: value.toDouble(),
          divisions: maxValue,
          min: minValue.toDouble(),
          max: maxValue.toDouble(),
          onChanged: (v) {
            callback(v.toInt());
          },
        ),
        Text(value.toString()),
      ],
    );
  }
}
