    #-- python
    pyright # python language server
    (python312.withPackages (
      ps:
        with ps; [
          black # python formatter
          ipykernel
          pip
          # my commonly used python packages
          tensorflow
          pandas
          numpy
          scikit-learn
          matplotlib
          seaborn
          kaggle
        ]
    ))

{
    pkgs.mkShell {
                # The Nix packages provided in the environment
                packages = [
                pkgs.python311
                pkgs.python311Packages.pip
                # Whatever other packages are required
                ];
                shellHook = ''
                python -m venv .venv
                source .venv/bin/activate
                pip install -r requirements.txt
                '';
    };
}