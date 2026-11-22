import json
import re
from pathlib import Path
from typing import List, Tuple


class TrieNode:
    def __init__(self):
        self.children = {}
        self.metadata = None


class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, path, _first_kind, _second_kind, _third_kind):
        current = self.root
        for char in path:
            if char not in current.children:
                current.children[char] = TrieNode()
            current = current.children[char]
        current.metadata = (_first_kind, _second_kind, _third_kind)

    def search(self, path):
        current = self.root
        longest_match_node = None

        for char in path:
            if char not in current.children:
                break
            current = current.children[char]
            if current.metadata:
                longest_match_node = current

        if longest_match_node:
            return longest_match_node.metadata
        else:
            return None


RuleTuple = Tuple[re.Pattern, str, str, str]


class PatternTrieNode:
    __slots__ = ('children', 'rules')

    def __init__(self):
        self.children: dict[str, PatternTrieNode] = {}
        self.rules: List[RuleTuple] = []


class PatternTrie:
    def __init__(self):
        self.root = PatternTrieNode()

    def insert(self, prefix: str, rules: List[RuleTuple]) -> None:
        node = self.root
        for char in prefix:
            if char not in node.children:
                node.children[char] = PatternTrieNode()
            node = node.children[char]
        node.rules.extend(rules)

    def search(self, path: str) -> List[RuleTuple]:
        best_rules: List[RuleTuple] = []
        node = self.root
        best_rules.extend(node.rules)
        for char in path:
            if char not in node.children:
                break
            node = node.children[char]
            if node.rules:
                best_rules.extend(node.rules)
        return best_rules

class SoFieldLookup:

    def __init__(self):
        self._PROC_DATA_PATTERN = re.compile(r"^/proc/.*/data/storage/.*")
        self.cache = {}

        self.trie = Trie()
        with open(Path(__file__).parent / 'rule_mapping.json', encoding='utf-8') as file:
            data = json.load(file)
        for key, value in data.items():
            first_kind = value["FirstKind"]
            for rule in value.get("Rule", []):
                second_kind = rule.get("SecondKind")
                third_kind = rule.get("ThirdKind")
                for lib in rule.get("Lib", []):
                    self.trie.insert(lib, first_kind, second_kind, third_kind)

        self.rule_trie = PatternTrie()
        with open(Path(__file__).parent / 'rule_pattern.json', encoding="utf-8") as f:
            data = json.load(f)
        for prefix, framework_dict in data.items():
            rule_list: List[RuleTuple] = []
            for framework_name, framework_info in framework_dict.items():
                first_kind = framework_info["FirstKind"]
                for rule in framework_info.get("Rule", []):
                    second_kind = rule["SecondKind"]
                    third_kind = rule["ThirdKind"]
                    for lib_pattern in rule.get("Lib", []):
                        compiled = re.compile(lib_pattern)
                        rule_list.append((compiled, first_kind, second_kind, third_kind))
            self.rule_trie.insert(prefix, rule_list)

    def __process_so_name(self, so_name: str):
        if self._PROC_DATA_PATTERN.match(so_name):
            idx = so_name.find("/data/storage/")
            if idx != -1:
                return so_name[idx:]
        return so_name

    def find_field(self, so):
        if so in self.cache:
            return self.cache[so]
        result = self.trie.search(so)
        if result is not None:
            _first_kind, _second_kind, _third_kind = result
            reprocess_so = self.__process_so_name(so)
            self.cache[so] = _first_kind, _second_kind, _third_kind, reprocess_so
            return _first_kind, _second_kind, _third_kind, reprocess_so
        rules = self.rule_trie.search(so)
        for rule in rules[::-1]:
            if rule[0].fullmatch(so):
                reprocess_so = self.__process_so_name(so)
                self.cache[so] = rule[1], rule[2], rule[3], reprocess_so
                return rule[1], rule[2], rule[3], reprocess_so
        self.cache[so] = None
        return None