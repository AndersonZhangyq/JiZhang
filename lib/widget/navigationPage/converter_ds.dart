import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class Item {
  final String id;
  final String name;

  Item({required this.name}) : id = DateTime.now().toString();
}

class Conversion {
  final Item from;
  final Item to;
  final double rate;
  final double fromValue; // 新增原始输入值
  final double toValue; // 新增原始输入值

  Conversion({
    required this.from,
    required this.to,
    required this.fromValue,
    required this.toValue,
  }) : rate = toValue / fromValue; // 自动计算比率
}

class AppState extends ChangeNotifier {
  final List<Item> _items = [];
  final List<Conversion> _conversions = [];

  List<Item> get items => _items;
  List<Conversion> get conversions => _conversions;

  void addItem(Item item) {
    // 检查重复单位（不区分大小写）
    final exists =
        _items.any((i) => i.name.toLowerCase() == item.name.toLowerCase());
    if (exists) {
      throw ArgumentError('单位 "${item.name}" 已存在');
    }

    _items.add(item);
    notifyListeners();
  }

  void addConversion(Conversion conversion) {
    // 检查重复转换关系（单向检查）
    final exists = _conversions.any(
        (c) => c.from.id == conversion.from.id && c.to.id == conversion.to.id);

    if (exists) {
      throw ArgumentError(
          '${conversion.from.name}→${conversion.to.name} 的转换关系已存在');
    }

    _conversions.add(conversion);
    notifyListeners();
  }

  double? getConversionRate(Item from, Item to) {
    for (var conv in _conversions) {
      if (conv.from == from && conv.to == to) {
        return conv.rate;
      }
    }
    return null;
  }

  void removeItem(Item item) {
    // 删除单位
    _items.removeWhere((element) => element.id == item.id);

    // 级联删除相关转换关系
    _conversions.removeWhere(
        (conv) => conv.from.id == item.id || conv.to.id == item.id);

    notifyListeners();
  }

  void removeConversion(Conversion conversion) {
    // 删除单个转换关系
    _conversions.remove(conversion);
    notifyListeners();
  }

  // 新增编辑方法
  void updateItem(Item oldItem, String newName) {
    final index = _items.indexWhere((i) => i.id == oldItem.id);
    _items[index] = Item(name: newName);
    notifyListeners();
  }

  void updateConversion(Conversion oldConv, double newFrom, double newTo) {
    final index = _conversions.indexWhere(
        (c) => c.from.id == oldConv.from.id && c.to.id == oldConv.to.id);
    _conversions[index] = Conversion(
      from: oldConv.from,
      to: oldConv.to,
      fromValue: newFrom,
      toValue: newTo,
    );
    notifyListeners();
  }
}

class ConverterDs extends StatefulWidget {
  const ConverterDs({Key? key}) : super(key: key);

  @override
  _ConverterDsState createState() => _ConverterDsState();
}

class _ConverterDsState extends State<ConverterDs> {
  final TextEditingController _itemNameController = TextEditingController();
  Item? _selectedFrom;
  Item? _selectedTo;
  final TextEditingController _conversionRateController =
      TextEditingController();
  final List<Item> _conversionPath = [];
  final TextEditingController _inputValueController = TextEditingController();
  List<String> _results = [];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _buildAddItemSection(),
              const SizedBox(height: 10),
              _buildAddConversionSection(),
              const SizedBox(height: 10),
              _buildConversionPathSection(),
              const SizedBox(height: 10),
              _buildResultsSection(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Center(
              child: Text('添加新单位',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(labelText: '单位名称'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                try {
                  if (_itemNameController.text.isNotEmpty) {
                    context.read<AppState>().addItem(
                          Item(name: _itemNameController.text.trim()),
                        );
                    _itemNameController.clear();
                  }
                } on ArgumentError catch (e) {
                  _showError(e.message);
                }
              },
              child: const Text('添加单位'),
            ),
            _buildItemsList(),
          ],
        ),
      ),
    );
  }

// 修改单位列表项
  Widget _buildItemsList() {
    final appState = context.watch<AppState>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: appState.items
              .map((item) => InputChip(
                    label: Text(item.name),
                    backgroundColor: Colors.blue[100],
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _confirmDeleteItem(context, item),
                    onPressed: () => _showEditItemDialog(context, item),
                  ))
              .toList(),
        ),
      ],
    );
  }

  void _confirmDeleteItem(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要永久删除「${item.name}」单位吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().removeItem(item);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

// 新增单位编辑对话框
  void _showEditItemDialog(BuildContext context, Item item) {
    final controller = TextEditingController(text: item.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("编辑单位"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "新名称"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<AppState>().updateItem(item, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  Widget _buildAddConversionSection() {
    final TextEditingController _fromValueController = TextEditingController();
    final TextEditingController _toValueController = TextEditingController();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('添加转换关系',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 第一行：From单位选择
            _buildConversionInputRow(
              controller: _fromValueController,
              selectedItem: _selectedFrom,
              onItemSelected: (item) => setState(() => _selectedFrom = item),
            ),

            // 向下箭头
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: Icon(Icons.arrow_downward_rounded,
                    size: 24, color: Colors.grey[600]),
              ),
            ),

            // 第二行：To单位选择
            _buildConversionInputRow(
              controller: _toValueController,
              selectedItem: _selectedTo,
              onItemSelected: (item) => setState(() => _selectedTo = item),
            ),

            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                try {
                  final fromVal = double.tryParse(_fromValueController.text);
                  final toVal = double.tryParse(_toValueController.text);

                  if (_selectedFrom == null || _selectedTo == null) {
                    _showError('请先选择转换单位');
                    return;
                  }

                  if (fromVal == null || toVal == null || toVal == 0) {
                    _showError('请输入有效的数值');
                    return;
                  }

                  if (_selectedFrom!.id == _selectedTo!.id) {
                    _showError('不能添加相同单位间的转换');
                    return;
                  }

                  context.read<AppState>().addConversion(
                        Conversion(
                          from: _selectedFrom!,
                          to: _selectedTo!,
                          fromValue: fromVal,
                          toValue: toVal,
                        ),
                      );
                  _fromValueController.clear();
                  _toValueController.clear();
                } on ArgumentError catch (e) {
                  _showError(e.message);
                }
              },
              child: const Text('确认添加'),
            ),
            _buildConversionsList(), // 新增转换比率显示
          ],
        ),
      ),
    );
  }

// 通用输入行组件
  Widget _buildConversionInputRow({
    required TextEditingController controller,
    required Item? selectedItem,
    required Function(Item?) onItemSelected,
  }) {
    final items = context.watch<AppState>().items;
    return Row(
      children: [
        // 单位选择下拉菜单
        Expanded(
          flex: 2,
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Item>(
                value: selectedItem,
                isDense: true,
                hint: const Text('选择单位', style: TextStyle(fontSize: 14)),
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: onItemSelected,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 数值输入框
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              suffixText: selectedItem?.name ?? '单位',
              suffixStyle: TextStyle(
                  color: selectedItem != null ? Colors.blue[700] : Colors.grey,
                  fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

// 修改转换关系列表项
  Widget _buildConversionsList() {
    final conversions = context.watch<AppState>().conversions;
    return Column(
      children: conversions
          .map((conv) => ListTile(
                title: Text(
                    "${conv.fromValue} ${conv.from.name} = ${conv.toValue} ${conv.to.name}"),
                subtitle: Text(
                    "比率：1 ${conv.from.name} ≈ ${conv.rate.toStringAsFixed(4)} ${conv.to.name}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditConversionDialog(context, conv),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteConversion(context, conv),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

// 新增编辑对话框
  void _showEditConversionDialog(BuildContext context, Conversion conv) {
    final fromController =
        TextEditingController(text: conv.fromValue.toString());
    final toController = TextEditingController(text: conv.toValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("编辑 ${conv.from.name} → ${conv.to.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: conv.from.name),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: toController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: conv.to.name),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              final newFrom = double.tryParse(fromController.text);
              final newTo = double.tryParse(toController.text);

              if (newFrom != null && newTo != null && newTo != 0) {
                context.read<AppState>().updateConversion(conv, newFrom, newTo);
                Navigator.pop(context);
              }
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConversion(BuildContext context, Conversion conv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${conv.from.name} → ${conv.to.name} 的转换关系吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().removeConversion(conv);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionPathSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('设置转换路径',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPathControls()),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() => _conversionPath.clear()),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildPathVisualization(), // 新增可视化路径
            const SizedBox(height: 14),
            TextField(
              controller: _inputValueController,
              decoration: const InputDecoration(
                labelText: '输入数值',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: _calculateConversion,
              child: const Text('开始计算'),
            ),
          ],
        ),
      ),
    );
  }

// 新增路径可视化组件
  Widget _buildPathVisualization() {
    if (_conversionPath.isEmpty) {
      return const Text('尚未选择任何单位', style: TextStyle(color: Colors.grey));
    }

    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // 设置为横向滑动
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // 确保内容左对齐
          children: _conversionPath
              .asMap()
              .entries
              .expand((entry) => [
                    _buildPathItem(entry.value, entry.key),
                    if (entry.key != _conversionPath.length - 1)
                      _buildArrowIcon(),
                  ])
              .toList(),
        ),
      ),
    );
  }

// 单个路径项组件
  Widget _buildPathItem(Item item, int idx) {
    return Tooltip(
      message: '点击删除',
      child: GestureDetector(
        onTap: () => setState(() => _conversionPath.removeAt(idx)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              Icon(Icons.close, size: 16, color: Colors.blue[700]),
            ],
          ),
        ),
      ),
    );
  }

// 箭头图标组件
  Widget _buildArrowIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child:
          Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.grey[600]),
    );
  }

// 路径控制组件
  Widget _buildPathControls() {
    final items = context.watch<AppState>().items;
    return DropdownButton<Item>(
      isExpanded: true,
      hint: const Text('选择要添加的单位'),
      value: null,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item.name),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _conversionPath.add(value));
        }
      },
    );
  }

  void _calculateConversion() {
    final appState = context.read<AppState>();
    final path = _conversionPath;
    final input = _inputValueController.text;

    if (path.length < 2) {
      _showError('请设置至少包含两个单位的转换路径');
      return;
    }

    final inputValue = double.tryParse(input);
    if (inputValue == null) {
      _showError('请输入有效数值');
      return;
    }

    List<String> results = [];
    double currentValue = inputValue;

    for (int i = 0; i < path.length - 1; i++) {
      final from = path[i];
      final to = path[i + 1];
      final rate = appState.getConversionRate(from, to);

      if (rate == null) {
        _showError('缺少 ${from.name} 到 ${to.name} 的转换关系');
        return;
      }

      final nextValue = currentValue * rate;
      results.add('${currentValue.toStringAsFixed(2)} ${from.name} = '
          '${nextValue.toStringAsFixed(2)} ${to.name}');
      currentValue = nextValue;
    }

    setState(() => _results = results);
  }

  Widget _buildResultsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('转换结果',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._results.map((result) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(result),
                )),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
