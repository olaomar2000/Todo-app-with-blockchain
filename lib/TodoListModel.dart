import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class TodoListModel extends ChangeNotifier {
  TodoListModel() {
    init();
  }

  String myAddress = '0x9E0EDd786410f903bc1687E5d72B15251eC911e4';
  late List<Task> todos = [];
  bool isLoading = true;
  late int taskCount;

 

  final String _privateKey =
      "your privet key";
  String contractName = "TodoContract";

  late Web3Client _client;
  late Client httpClient;

  late String _abiCode;

  late Credentials _credentials;
  late EthereumAddress _contractAddress;
  late EthereumAddress _ownAddress;
  late DeployedContract _contract;

  late ContractFunction _taskCount;
  late ContractFunction _todos;
  late ContractFunction _createTask;
  late ContractFunction _updateTask;
  late ContractFunction _deleteTask;
  late ContractFunction _toggleComplete;
  String ethereumClientUrl =
      'https://rinkeby.infura.io/v3/f400414423bb436491206648eef496da';

  Future<void> init() async {
    _client = Web3Client(ethereumClientUrl, Client());

    await getCredentials();
    await getContract();
  }

  Future<void> getContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0x683920d2d7A218218b1FBEDE4b41a2e4E252276D";

    _contract = DeployedContract(
      ContractAbi.fromJson(abi, contractName),
      EthereumAddress.fromHex(contractAddress),
    );
    _taskCount = _contract.function("taskCount");
    _updateTask = _contract.function("updateTask");
    _createTask = _contract.function("createTask");
    _deleteTask = _contract.function("deleteTask");
    _toggleComplete = _contract.function("toggleComplete");
    _todos = _contract.function("todos");

    await getTodos();
    notifyListeners();
  }

  Future<void> getCredentials() async {
    _credentials = EthPrivateKey.fromHex(
        "336c53e1bc03af296c3b56e9b305536c830511243d31d40b2c410340e6b4e4b7");
    _ownAddress = await _credentials.extractAddress();
  }

  getTodos() async {
    List totalTaskList = await _client
        .call(contract: _contract, function: _taskCount, params: []);
    notifyListeners();
    BigInt totalTask = totalTaskList[0];
    taskCount = totalTask.toInt();
    todos.clear();
    for (var i = 0; i < totalTask.toInt(); i++) {
      var temp = await _client.call(
          contract: _contract, function: _todos, params: [BigInt.from(i)]);
      if (temp[1] != "") {
        todos.add(
          Task(
            id: (temp[0] as BigInt).toInt(),
            taskName: temp[1],
            isCompleted: temp[2],
          ),
        );
        notifyListeners();
      }
      notifyListeners();
    }
    isLoading = false;
    todos = todos.reversed.toList();
    notifyListeners();
  }

  addTask(String taskNameData) async {
    isLoading = true;
    notifyListeners();
    await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _createTask,
        parameters: [taskNameData],
      ),
      chainId: 4,
    );
    await getTodos();
    notifyListeners();
  }

  updateTask(int id, String taskNameData) async {
    isLoading = true;
    notifyListeners();
    await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _updateTask,
        parameters: [BigInt.from(id), taskNameData],
      ),
      chainId: 4,
    );
    await getTodos();
    notifyListeners();
  }

  deleteTask(int id) async {
    isLoading = true;
    notifyListeners();
    await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _deleteTask,
        parameters: [BigInt.from(id)],
      ),
      chainId: 4,
    );
    await getTodos();
    notifyListeners();
  }

  toggleComplete(int id) async {
    isLoading = true;
    notifyListeners();
    await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _toggleComplete,
        parameters: [BigInt.from(id)],
      ),
      chainId: 4,
    );
    await getTodos();
    notifyListeners();
  }
}

class Task {
  final int id;
  final String taskName;
  final bool isCompleted;
  Task({required this.id, required this.taskName, required this.isCompleted});
}
