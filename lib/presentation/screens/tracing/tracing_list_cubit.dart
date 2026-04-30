import 'package:arunika_app/data/models/response/tracing_item.dart';
import 'package:arunika_app/data/repositories/tracing_repository.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_list_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TracingListCubit extends Cubit<TracingListState> {
  final TracingRepository repository;
  TracingListCubit({required this.repository}) : super(TracingListInitial());

  Future<void> load({String? type}) async {
    emit(TracingListLoading());
    try {
      final items = await repository.getItems(type: type);
      emit(TracingListLoaded(items: items, activeType: type));
    } catch (e) {
      emit(TracingListError(e.toString()));
    }
  }
}
