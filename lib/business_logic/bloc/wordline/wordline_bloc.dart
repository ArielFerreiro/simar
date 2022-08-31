// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:simar/data/model/wordline_reply.dart';
import 'package:simar/data/repository/wordline_repository.dart';

part 'wordline_event.dart';
part 'wordline_state.dart';

class WordlineBloc extends Bloc<WordlineEvent, WordlineState> {
  final WordlineRepository repository;

  WordlineBloc({required this.repository}) : super(WordlineInitial()) {
    on<WordlineEvent>((event, emit) async {
      if (event is RetrieveWordlineData) {
        emit(WordlineLoading());
        WordLineReply? reply = await repository.retrieveWordLineReply(event.um);
        if (reply != null) {
          emit(WordlineDataLoaded(data: reply));
        } else {
          emit(WordlineNoData());
        }
      } else if (event is ResetState) {
        emit(WordlineInitial());
      }
    });
  }
}
