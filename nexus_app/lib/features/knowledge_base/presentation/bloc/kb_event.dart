import 'package:equatable/equatable.dart';

abstract class KBEvent extends Equatable {
  const KBEvent();
  @override
  List<Object> get props => [];
}

class KBLoadRequested extends KBEvent {
  const KBLoadRequested();
}

class KBCreateRequested extends KBEvent {
  final String name;
  final String description;
  const KBCreateRequested({required this.name, required this.description});
  @override
  List<Object> get props => [name, description];
}