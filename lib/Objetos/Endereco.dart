class Endereco
{
   String? cep;
   String? logradouro;
   String? localidade;
   String? complemento;
   String? bairro;
   String? uf;
   String? unidade;
   String? ibge;
   String? gia;

   Endereco({this.cep,
   this.logradouro,
   this.localidade,
   this.complemento,
   this.bairro,
   this.uf,
   this.unidade,
   this.ibge,
   this.gia});

   Endereco.fromMap(dynamic json) {
     cep = json['cep'];
     logradouro = json['logradouro'];
     localidade = json['localidade'];
     complemento = json['complemento'];
     bairro = json['bairro'];
     uf = json['uf'];
     unidade = json['unidade'];
     ibge = json['ibge'];
     gia = json['gia'];
   }

}