import 'package:flutter/material.dart';
import '../models/checklist.dart';

class ChecklistWidget extends StatefulWidget {
  final String taskId;
  final List<TaskChecklist> checklists;
  final bool isLoading;
  final Function(String title) onAddChecklist;
  final Function(String id, bool isDone) onToggleChecklist;
  final Function(String id) onDeleteChecklist;

  const ChecklistWidget({
    super.key,
    required this.taskId,
    required this.checklists,
    required this.isLoading,
    required this.onAddChecklist,
    required this.onToggleChecklist,
    required this.onDeleteChecklist,
  });

  @override
  State<ChecklistWidget> createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      if (text.length > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist item title cannot exceed 100 characters.')),
        );
        return;
      }
      widget.onAddChecklist(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.checklists.length;
    final doneCount = widget.checklists.where((c) => c.isDone).length;
    final progress = total > 0 ? doneCount / total : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fact_check_outlined, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Checklist',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '$doneCount/$total completed (${(progress * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 ? Colors.green : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
            else if (widget.checklists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No checklist items yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.checklists.length,
                itemBuilder: (context, index) {
                  final item = widget.checklists[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Checkbox(
                      value: item.isDone,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        if (val != null) {
                          widget.onToggleChecklist(item.id, val);
                        }
                      },
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                        color: item.isDone ? Colors.grey : null,
                        fontSize: 14,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                      onPressed: () => widget.onDeleteChecklist(item.id),
                    ),
                  );
                },
              ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: 'Add checklist item...',
                      counterText: '',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleAdd(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: Colors.blue),
                  onPressed: _handleAdd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
