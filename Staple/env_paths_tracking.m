function paths = env_paths_tracking(varargin)
    paths.eval_set_base = '/home/berti/cfnet/data/'; % e.g. '/home/berti/datasets/';
    paths = vl_argparse(paths, varargin);
end
