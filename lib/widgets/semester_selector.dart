import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/semester_provider.dart';
import 'glass_card.dart';

class SemesterSelector extends ConsumerWidget {
  const SemesterSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersCount = ref.watch(
      semesterProvider.select((s) => s.semesters.length),
    );
    final selectedIndex = ref.watch(
      semesterProvider.select((s) => s.selectedIndex),
    );

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: semestersCount + 1, // +1 for the add button
            itemBuilder: (context, index) {
              if (index == semestersCount) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(semesterProvider.notifier).addSemester();
                    },
                    child: GlassCard(
                      useBlur: false,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: BorderRadius.circular(25),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          color: Colors.cyanAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final isSelected = index == selectedIndex;
              final semesterName = ref.watch(
                semesterProvider.select((s) => s.semesters[index].name),
              );

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    ref.read(semesterProvider.notifier).selectSemester(index);
                  },
                  onLongPress: () {
                    if (semestersCount > 1) {
                      _showDeleteDialog(context, ref, index, semesterName);
                    }
                  },
                  child: GlassCard(
                    useBlur: false,
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    borderRadius: BorderRadius.circular(25),
                    borderColor: isSelected ? Colors.cyanAccent : null,
                    opacity: isSelected ? 0.2 : 0.1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          semesterName,
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.cyanAccent
                                : Colors.white70,
                          ),
                        ),
                        if (semestersCount > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showDeleteDialog(
                              context,
                              ref,
                              index,
                              semesterName,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: isSelected
                                  ? Colors.cyanAccent.withValues(alpha: 0.6)
                                  : Colors.white30,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    int index,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3D),
        title: Text(
          'Delete $name?',
          style: GoogleFonts.lexend(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to remove this semester and all its courses?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(semesterProvider.notifier).removeSemester(index);
              Navigator.pop(context);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
