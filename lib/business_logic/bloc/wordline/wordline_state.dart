part of 'wordline_bloc.dart';

@immutable
abstract class WordlineState extends Equatable {
  @override
  List<Object> get props => [];
}

class WordlineInitial extends WordlineState {}

class WordlineLoading extends WordlineState {}

class WordlineNoData extends WordlineState {}

class WordlineFailure extends WordlineState {}

class WordlineDataLoaded extends WordlineState {
  final WordLineReply data;

  WordlineDataLoaded({required this.data});

  @override
  List<Object> get props => [data];
}
