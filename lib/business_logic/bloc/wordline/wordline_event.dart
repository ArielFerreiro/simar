part of 'wordline_bloc.dart';

@immutable
abstract class WordlineEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ResetState extends WordlineEvent {}

class RetrieveWordlineData extends WordlineEvent {
  final String um;

  RetrieveWordlineData({required this.um});

  @override
  List<Object> get props => [um];
}
