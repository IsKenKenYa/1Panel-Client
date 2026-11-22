from types import MappingProxyType
from collections.abc import Mapping


class OptimizedCallChain:
    TABLE_DICT = None

    def __init__(self, _data=None):
        if _data is None:
            _data = []
        assert self.TABLE_DICT is not None, "TABLE_DICT should be initialized first"
        self.items = []

        for _item in _data:
            self.append(_item)

    def __getitem__(self, key):
        if isinstance(key, int):
            return self.items[key]
        else:
            raise KeyError(f"Invalid key type: {type(key)}")

    def __iter__(self):
        return iter(self.items)

    def __repr__(self):
        return f"{self.items}"

    def __delitem__(self, key):
        del self.items[key]

    def __len__(self):
        return len(self.items)

    @classmethod
    def init_table_dict(cls, _table_dict: dict[int, str]):
        cls.TABLE_DICT = MappingProxyType(_table_dict)

    def to_dict(self):
        res = []
        for _i in self.items:
            frames = []
            for _f in _i['frames']:
                frames.append({
                    "depth": _f["depth"],
                    "symbol_id": _f["symbol_id"],
                    "symbol_data": _f["symbol_data"],
                    "file_data": _f["file_data"],
                    "file_id": _f["file_id"]
                })
            _item = _i.copy()
            _item.update(
                {
                    'frames': frames
                }
            )
            res.append(_item)
        return res

    def append(self, _item):
        frames = _item['frames']
        _item['frames'] = []

        for _frame in frames:
            if isinstance(_frame, Frame):
                _item['frames'].append(_frame)
            else:
                _item['frames'].append(Frame(_frame, self.TABLE_DICT))

        self.items.append(_item)


class Frame(Mapping):
    def __init__(self, frame_data, data_pool: MappingProxyType):
        self.data_pool: MappingProxyType = data_pool
        self.depth = frame_data.get('depth')
        self.sid = frame_data.get('symbol_id')
        self.fid = frame_data.get('file_id')

    def __getitem__(self, key):
        """
        支持通过键访问 'symbol_data' 和 'file_data'
        """
        if key == "symbol_data":
            # 返回 symbol_data，通过索引从 data_pool 获取
            if self.sid is not None:
                return self.data_pool[self.sid]
            return None
        elif key == "file_data":
            # 返回 file_data，通过索引从 data_pool 获取
            if self.fid is not None:
                return self.data_pool[self.fid]
            return None
        elif key == "depth":
            return self.depth
        elif key == "symbol_id":
            return self.sid
        elif key == "file_id":
            return self.fid
        else:
            raise KeyError(f"Invalid key: {key}")

    def keys(self):
        return "symbol_data", "file_data", "depth"

    def __iter__(self):
        return iter(self.keys())

    def __repr__(self):
        return (f"{{'depth': {self.depth}, "
                f"'symbol_data': '{self.data_pool.get(self.sid, None)}', "
                f"'file_data': '{self.data_pool.get(self.fid, None)}'}}")

    def __len__(self):
        return 3