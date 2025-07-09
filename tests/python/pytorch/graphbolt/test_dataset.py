import backend as F
import pytest

if not F.is_hip():
    import dgl.graphbolt as gb
else:
    pytest.skip("Graphbolt unsupported in ROCm DGL", allow_module_level=True)


def test_Dataset():
    dataset = gb.Dataset()
    with pytest.raises(NotImplementedError):
        _ = dataset.tasks
    with pytest.raises(NotImplementedError):
        _ = dataset.graph
    with pytest.raises(NotImplementedError):
        _ = dataset.feature
    with pytest.raises(NotImplementedError):
        _ = dataset.dataset_name
